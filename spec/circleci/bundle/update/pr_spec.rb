# frozen_string_literal: true

describe Circleci::Bundle::Update::Pr do
  describe '.github_host' do
    subject { Circleci::Bundle::Update::Pr.send(:github_host) }

    after { ENV['CIRCLE_REPOSITORY_URL'] = nil }

    context "when ENV['CIRCLE_REPOSITORY_URL'] is git@github.com:masutaka/compare_linker.git" do
      before { ENV['CIRCLE_REPOSITORY_URL'] = 'git@github.com:masutaka/compare_linker.git' }

      it { is_expected.to eq 'github.com' }
    end

    context "when ENV['CIRCLE_REPOSITORY_URL'] is https://github.com/masutaka/circleci-bundle-update-pr.git" do
      before { ENV['CIRCLE_REPOSITORY_URL'] = 'https://github.com/masutaka/circleci-bundle-update-pr.git' }

      it { is_expected.to eq 'github.com' }
    end

    context "with ENV['CIRCLE_REPOSITORY_URL'] is nil" do
      before { ENV['CIRCLE_REPOSITORY_URL'] = nil }

      it { is_expected.to eq 'github.com' }
    end
  end

  describe '.target_branch?' do
    subject do
      Circleci::Bundle::Update::Pr.send(
        :target_branch?,
        running_branch: running_branch,
        target_branches: ['target']
      )
    end

    context 'when running_target is included in target branches' do
      let(:running_branch) { 'target' }

      it { is_expected.to be_truthy }
    end

    context "when ENV['CIRCLE_BRANCH'] is not included in target branches" do
      let(:running_branch) { 'not_included' }

      it { is_expected.to be_falsy }
    end

    context "when ENV['CIRCLE_BRANCH'] is nil" do
      let(:running_branch) { nil }

      it { is_expected.to be_falsy }
    end
  end

  describe '.lockfile_path' do
    subject { Circleci::Bundle::Update::Pr.send(:lockfile_path) }

    let(:workdir_env) { Dir.getwd }

    before { ENV['CIRCLE_WORKING_DIRECTORY'] = workdir_env }

    after { ENV['CIRCLE_WORKING_DIRECTORY'] = nil }

    context 'when Gemfile.lock is in the working dir' do
      it { is_expected.to eq 'Gemfile.lock' }
    end

    context "when ENV['CIRCLE_WORKING_DIRECTORY'] is not set" do
      let(:workdir_env) {}

      it { is_expected.to eq 'Gemfile.lock' }
    end

    context 'when Gemfile.lock is in a nested dir' do
      let(:src_dir) { 'spec/tmp' }

      before do
        FileUtils.mkdir_p(src_dir) && FileUtils.touch('Gemfile.lock')
      end

      it 'is "spec/tmp/Gemfile.lock"' do
        Dir.chdir(src_dir) do
          expect(subject).to eq 'spec/tmp/Gemfile.lock'
        end
      end
    end
  end
end
