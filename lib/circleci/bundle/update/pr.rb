require "circleci/bundle/update/pr/version"
require "octokit"
require "compare_linker"
require 'net/http'
module Circleci
  module Bundle
    module Update
      module Pr
        def self.create_if_needed(git_username: nil, git_email: nil, git_branches: ["master"],
                                  assignees: nil, reviewers: nil, labels: nil)
          raise_if_env_unvalid!

          if skip?
            puts 'Skip because it has already existed.'
            return
          end

          unless need_to_commit?(git_branches)
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

        BRANCH_PREFIX = 'bundle-update-'.freeze
        TITLE_PREFIX = 'bundle update at '.freeze

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

        # Has 'bundle update PR' already existed?
        #
        # @return [Boolean]
        def self.skip?
          client.pull_requests(repo_full_name).find do |pr|
            pr.title =~ /\A#{TITLE_PREFIX}/ && pr.head.ref =~ /\A#{BRANCH_PREFIX}\d+/
          end != nil
        end
        private_class_method :skip?

        # Does it need to commit due to bundle update?
        #
        # @param git_branches [Array<String>]
        # @return [Boolean]
        def self.need_to_commit?(git_branches)
          return false unless git_branches.include?(ENV['CIRCLE_BRANCH'])
          unless system("bundle update && bundle update --ruby")
            raise "Unable to execute `bundle update && bundle update --ruby`"
          end
          `git status -sb 2> /dev/null`.include?("Gemfile.lock")
        end
        private_class_method :need_to_commit?

        # Create remote branch for bundle update PR
        #
        # @return [String] remote branch name. e.g. bundle-update-20180929154455
        def self.create_branch(git_username, git_email)
          branch = "#{BRANCH_PREFIX}#{now.strftime('%Y%m%d%H%M%S')}"
          remote = "https://#{github_access_token}@#{github_host}/#{repo_full_name}"
          system("git remote add github-url-with-token #{remote}")
          system("git config user.name #{git_username}")
          system("git config user.email #{git_email}")
          system("git add Gemfile.lock")
          system("git commit -m '$ bundle update && bundle update --ruby'")
          system("git branch -M #{branch}")
          system("git push -q github-url-with-token #{branch}")
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
          ENV["OCTOKIT_ACCESS_TOKEN"] = ENV["GITHUB_ACCESS_TOKEN"]
          compare_linker = CompareLinker.new(repo_full_name, pr_number)
          compare_linker.formatter = CompareLinker::Formatter::Markdown.new
          compare_linker_list = compare_linker.make_compare_links.to_a
          compare_linker_list.map! do |link|
            changelog_link = "#{link.match(/\((.*?)\)/)[1]}/blob/master/CHANGELOG.md"
            link_exist?(changelog_link)? link << ": [CHANGELOG](#{changelog_link})" : link
          end

          body = <<-EOB
**Updated RubyGems:**

#{compare_linker_list.join("\n")}

Powered by [circleci-bundle-update-pr](https://rubygems.org/gems/circleci-bundle-update-pr)
          EOB

          client.update_pull_request(repo_full_name, pr_number, body: body)
        end
        private_class_method :update_pull_request_body

        REDIRECT_MAX_TIMES = 5.freeze

        def link_exist?(link, limit = REDIRECT_MAX_TIMES)
          if limit == 0
            return false
          end
          begin
            response = Net::HTTP.get_response(URI.parse(link))
          rescue
            return false
          else
            case response
            when Net::HTTPSuccess
              return true
            when Net::HTTPRedirection
              link_exist?(response['location'], limit - 1)
            else
              return false
            end
          end
        end
        private_class_method :link_exist?

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
            Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
          end
        end
        private_class_method :client

        def self.enterprise?
          !!ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN']
        end
        private_class_method :enterprise?

        def self.github_access_token
          enterprise? ? ENV['ENTERPRISE_OCTOKIT_ACCESS_TOKEN'] : ENV['GITHUB_ACCESS_TOKEN']
        end
        private_class_method :github_access_token

        # Get repository full name
        #
        # @return [String] e.g. 'masutaka/circleci-bundle-update-pr'
        def self.repo_full_name
          @repo_full_name ||= "#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}"
        end
        private_class_method :repo_full_name

        def self.github_host
          # A format like https://github.com/masutaka/circleci-bundle-update-pr.git
          return $1 if ENV['CIRCLE_REPOSITORY_URL'] =~ %r{https://(.+?)/}
          # A format like git@github.com:masutaka/compare_linker.git
          return $1 if ENV['CIRCLE_REPOSITORY_URL'] =~ %r{([^@]+?):}
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
      end
    end
  end
end
