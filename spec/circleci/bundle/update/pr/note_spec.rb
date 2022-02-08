# frozen_string_literal: true

require 'tmpdir'

describe Circleci::Bundle::Update::Pr::Note do
  let!(:home_dir) { Dir.pwd }
  let(:work_dir) { Dir.mktmpdir }

  before do
    Dir.chdir work_dir
    Dir.mkdir '.circleci'
  end

  after do
    Dir.chdir home_dir
    FileUtils.rm_rf work_dir
  end

  describe '.exist?' do
    subject { Circleci::Bundle::Update::Pr::Note.exist? }

    context 'with only .circleci/BUNDLE_UPDATE_NOTE.md' do
      before do
        FileUtils.touch('.circleci/BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to be_truthy }
    end

    context 'with only CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        FileUtils.touch('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to be_truthy }
    end

    context 'with .circleci/BUNDLE_UPDATE_NOTE.md and CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        FileUtils.touch('.circleci/BUNDLE_UPDATE_NOTE.md')
        FileUtils.touch('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to be_truthy }
    end

    context 'with nothing' do
      it { is_expected.to be_falsy }
    end
  end

  describe '.read' do
    subject { Circleci::Bundle::Update::Pr::Note.read }

    context 'with .circleci/BUNDLE_UPDATE_NOTE.md' do
      before do
        File.write('.circleci/BUNDLE_UPDATE_NOTE.md', 'I am .circleci/BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to eq 'I am .circleci/BUNDLE_UPDATE_NOTE.md' }
    end

    context 'with CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        File.write('CIRCLECI_BUNDLE_UPDATE_NOTE.md', 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to eq 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md' }
    end

    context 'with .circleci/BUNDLE_UPDATE_NOTE.md and CIRCLECI_BUNDLE_UPDATE_NOTE.md' do
      before do
        File.write('.circleci/BUNDLE_UPDATE_NOTE.md', 'I am .circleci/BUNDLE_UPDATE_NOTE.md')
        File.write('CIRCLECI_BUNDLE_UPDATE_NOTE.md', 'I am CIRCLECI_BUNDLE_UPDATE_NOTE.md')
      end

      it { is_expected.to eq 'I am .circleci/BUNDLE_UPDATE_NOTE.md' }
    end

    context 'with nothing' do
      it { is_expected.to be_nil }
    end
  end
end
