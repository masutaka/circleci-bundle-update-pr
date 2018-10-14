describe Circleci::Bundle::Update::Pr::Note do
  describe '.exist?' do
    subject { Circleci::Bundle::Update::Pr::Note.exist? }

    context 'given only .circleci/BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return false
      end

      it { is_expected.to be_truthy }
    end

    context 'given only CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return false
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return true
      end

      it { is_expected.to be_truthy }
    end

    context 'given .circleci/BUNDLE_UPDATE_NOTE.md and CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return true
      end

      it { is_expected.to be_truthy }
    end

    context 'given nothing' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return false
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return false
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.read' do
    subject { Circleci::Bundle::Update::Pr::Note.read }

    context 'given .circleci/BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return false
        allow(File).to receive(:read).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return 'I am .circleci/BUNDLE_UPDATE_NOTE.md'
      end

      it { is_expected.to eq 'I am .circleci/BUNDLE_UPDATE_NOTE.md' }
    end

    context 'given CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return false
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:read).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md'
      end

      it { is_expected.to eq 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md' }
    end

    context 'given .circleci/BUNDLE_UPDATE_NOTE.md and CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return true
        allow(File).to receive(:read).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return 'I am .circleci/BUNDLE_UPDATE_NOTE.md'
        allow(File).to receive(:read).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md'
      end

      it { is_expected.to eq 'I am .circleci/BUNDLE_UPDATE_NOTE.md' }
    end

    context 'given nothing' do
      before do
        allow(File).to receive(:exist?).with('.circleci/BUNDLE_UPDATE_NOTE.md').and_return false
        allow(File).to receive(:exist?).with('CIRCLECI_BUNDLE_UPDATE_NOTE.md').and_return false
      end

      it { is_expected.to be_nil }
    end
  end
end
