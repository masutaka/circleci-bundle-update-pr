# frozen_string_literal: true

describe Circleci::Bundle::Update::Pr do
  describe '.github_host' do
    subject { Circleci::Bundle::Update::Pr.send(:github_host) }
    after { ENV['CIRCLE_REPOSITORY_URL'] = nil }

    context 'given git@github.com:masutaka/compare_linker.git' do
      before { ENV['CIRCLE_REPOSITORY_URL'] = 'git@github.com:masutaka/compare_linker.git' }

      it { is_expected.to eq 'github.com' }
    end

    context 'given https://github.com/masutaka/circleci-bundle-update-pr.git' do
      before { ENV['CIRCLE_REPOSITORY_URL'] = 'https://github.com/masutaka/circleci-bundle-update-pr.git' }

      it { is_expected.to eq 'github.com' }
    end

    context 'given nil' do
      before { ENV['CIRCLE_REPOSITORY_URL'] = nil }

      it { is_expected.to eq 'github.com' }
    end
  end

  describe '.target_branch?' do
    subject do
      Circleci::Bundle::Update::Pr.send(
        :target_branch?,
        running_branch: running_branch,
        target_branches: ['target'],
      )
    end

    context 'running_target is included in target branches' do
      let(:running_branch) { 'target' }

      it { is_expected.to be_truthy }
    end

    context "ENV['CIRCLE_BRANCH'] is not included in target branches" do
      let(:running_branch) { 'not_included' }

      it { is_expected.to be_falsy }
    end

    context "ENV['CIRCLE_BRANCH'] is nil" do
      let(:running_branch) { nil }

      it { is_expected.to be_falsy }
    end
  end
end
