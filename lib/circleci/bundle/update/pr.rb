require 'circleci/bundle/update/pr/version'
require 'octokit'
require 'compare_linker'
require 'circleci/bundle/update/pr/note'

module Circleci
  module Bundle
    module Update
      module Pr
        def self.create_if_needed(git_username: nil, git_email: nil, git_branches: ['master'],
                                  assignees: nil, reviewers: nil, labels: nil, allow_dup_pr: false)
          raise_if_env_unvalid!

          if skip?(allow_dup_pr)
            puts 'Skip because it has already existed.'
            return
          end

          unless target_branch?(running_branch: ENV['CIRCLE_BRANCH'], target_branches: git_branches)
            puts "Skip because CIRCLE_BRANCH[#{ENV['CIRCLE_BRANCH']}] is not included in target branches[#{git_branches.join(',')}]."
            return
          end

          unless need_to_commit?
            puts 'No changes due to bundle update'
            return
          end

          git_username ||= client.user.login
          git_email ||= "#{git_username}@users.noreply.#{github_host}"

          branch = create_branch(git_username, git_email)
          pull_request = create_pull_request(branch)
          add_labels(pull_request[:number], labels) if labels
          update_pull_request_body(pull_request[:number])
          add_assignees(pull_request[:number], assignees) if assignees
          request_review(pull_request[:number], reviewers) if reviewers
        end

        BRANCH_PREFIX = ENV['BRANCH_PREFIX'] || 'bundle-update-'.freeze
        TITLE_PREFIX = ENV['TITLE_PREFIX'] || 'bundle update at '.freeze

        def self.raise_if_env_unvalid!
          raise "$CIRCLE_PROJECT_USERNAME isn't set" unless ENV['CIRCLE_PROJECT_USERNAME']
          raise "$CIRCLE_PROJECT_REPONAME isn't set" unless ENV['CIRCLE_PROJECT_REPONAME']
          raise "$GITHUB_ACCESS_TOKEN isn't set" unless ENV['GITHUB_ACCESS_TOKEN']
          if ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN'] && !ENV['ENTERPRISE_OCTOKIT_API_ENDPOINT']
            raise "$ENTERPRISE_OCTOKIT_API_ENDPOINT isn't set"
          end
          if !ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN'] && ENV['ENTERPRISE_OCTOKIT_API_ENDPOINT']
            raise "$ENTERPRISE_OCTOKIT_ACCESS_TOKEN isn't set"
          end
        end
        private_class_method :raise_if_env_unvalid!

        # Should skip to make PR?
        #
        # @param allow_dup_pr [Boolean]
        # @return [Boolean]
        def self.skip?(allow_dup_pr)
          return false if allow_dup_pr

          exists_bundle_update_pr?
        end
        private_class_method :skip?

        # Has 'bundle update PR' already existed?
        #
        # @return [Boolean]
        def self.exists_bundle_update_pr?
          client.pull_requests(repo_full_name).find do |pr|
            pr.title =~ /\A#{TITLE_PREFIX}/ && pr.head.ref =~ /\A#{BRANCH_PREFIX}\d+/
          end != nil
        end
        private_class_method :exists_bundle_update_pr?

        # Is running branch included in target_branches?
        #
        # @param running_branch [String]
        # @param target_branches [Array<String>]
        # @return [Boolean]
        def self.target_branch?(running_branch:, target_branches:)
          target_branches.include?(running_branch)
        end
        private_class_method :target_branch?

        # Does it need to commit due to bundle update?
        #
        # @return [Boolean]
        def self.need_to_commit?
          old_lockfile = File.read('Gemfile.lock')

          unless system('bundle update && bundle update --ruby')
            raise 'Unable to execute `bundle update && bundle update --ruby`'
          end

          new_lockfile = File.read('Gemfile.lock')

          old_lockfile != new_lockfile
        end
        private_class_method :need_to_commit?

        # Create remote branch for bundle update PR
        #
        # @return [String] remote branch name. e.g. bundle-update-20180929154455
        def self.create_branch(git_username, git_email)
          branch = "#{BRANCH_PREFIX}#{now.strftime('%Y%m%d%H%M%S')}"

          current_ref = client.ref(repo_full_name, "heads/#{ENV['CIRCLE_BRANCH']}")
          branch_ref = client.create_ref(repo_full_name, "heads/#{branch}", current_ref.object.sha)

          branch_commit = client.commit(repo_full_name, branch_ref.object.sha)

          lockfile = File.read('Gemfile.lock')
          lockfile_blob_sha = client.create_blob(repo_full_name, lockfile)
          tree = client.create_tree(
            repo_full_name,
            [
              {
                path: lockfile_path,
                mode: '100644',
                type: 'blob',
                sha: lockfile_blob_sha
              }
            ],
            base_tree: branch_commit.commit.tree.sha
          )

          commit = client.create_commit(
            repo_full_name,
            '$ bundle update && bundle update --ruby',
            tree.sha,
            branch_ref.object.sha,
            author: {
              name: git_username,
              email: git_email
            }
          )

          client.update_ref(repo_full_name, "heads/#{branch}", commit.sha)

          puts "#{branch} is created"

          branch
        end
        private_class_method :create_branch

        # Create bundle update PR
        #
        # @param branch [String] branch name
        # @return [Sawyer::Resource] The newly created pull request
        def self.create_pull_request(branch)
          title = "#{TITLE_PREFIX}#{now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
          client.create_pull_request(repo_full_name, ENV['CIRCLE_BRANCH'], branch, title)
        end
        private_class_method :create_pull_request

        def self.add_labels(pr_number, labels)
          client.add_labels_to_an_issue(repo_full_name, pr_number, labels)
        end
        private_class_method :add_labels

        def self.update_pull_request_body(pr_number)
          ENV['OCTOKIT_ACCESS_TOKEN'] = ENV['GITHUB_ACCESS_TOKEN']
          compare_linker = CompareLinker.new(repo_full_name, pr_number)
          compare_linker.formatter = CompareLinker::Formatter::Markdown.new

          body = <<-PR_BODY
**Updated RubyGems:**

#{compare_linker.make_compare_links.to_a.join("\n")}

Powered by [circleci-bundle-update-pr](https://rubygems.org/gems/circleci-bundle-update-pr)
          PR_BODY

          if Note.exist?
            body << <<-PR_BODY

---

#{Note.read}
            PR_BODY
          end

          client.update_pull_request(repo_full_name, pr_number, body: body)
        end
        private_class_method :update_pull_request_body

        def self.add_assignees(pr_number, assignees)
          client.add_assignees(repo_full_name, pr_number, assignees)
        end
        private_class_method :add_assignees

        def self.request_review(pr_number, reviewers)
          client.request_pull_request_review(repo_full_name, pr_number, reviewers)
        end
        private_class_method :request_review

        def self.client
          if enterprise?
            Octokit::Client.new(access_token: ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN'],
                                api_endpoint: ENV['ENTERPRISE_OCTOKIT_API_ENDPOINT'])
          else
            Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
          end
        end
        private_class_method :client

        def self.enterprise?
          !!ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN']
        end
        private_class_method :enterprise?

        # Get repository full name
        #
        # @return [String] e.g. 'masutaka/circleci-bundle-update-pr'
        def self.repo_full_name
          @repo_full_name ||= "#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}"
        end
        private_class_method :repo_full_name

        def self.github_host
          # A format like https://github.com/masutaka/circleci-bundle-update-pr.git
          return Regexp.last_match(1) if ENV['CIRCLE_REPOSITORY_URL'] =~ %r{https://(.+?)/}
          # A format like git@github.com:masutaka/compare_linker.git
          return Regexp.last_match(1) if ENV['CIRCLE_REPOSITORY_URL'] =~ /([^@]+?):/

          'github.com'
        end
        private_class_method :github_host

        # Get unified current time
        #
        # @return [Time]
        def self.now
          @now ||= Time.now
        end
        private_class_method :now

        # Get Gemfile.lock path relative to workdir
        #
        # @return [String]
        def self.lockfile_path
          return 'Gemfile.lock' unless ENV['CIRCLE_WORKING_DIRECTORY']

          workdir = Pathname.new(File.expand_path(ENV['CIRCLE_WORKING_DIRECTORY']))
          gemfile_lock = Pathname.new(File.expand_path('Gemfile.lock'))
          gemfile_lock.relative_path_from(workdir).to_s
        end
        private_class_method :lockfile_path
      end
    end
  end
end
