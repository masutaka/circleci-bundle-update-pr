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
end
