module Circleci
  module Bundle
    module Update
      module Pr
        class Note
          def self.exist?
            File.exist?('.circleci/BUNDLE_UPDATE_NOTE.md') ||
              File.exist?('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
          end

          def self.read
            if File.exist?('.circleci/BUNDLE_UPDATE_NOTE.md')
              File.read('.circleci/BUNDLE_UPDATE_NOTE.md')
            elsif File.exist?('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
              File.read('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
            end
          end
        end
      end
    end
  end
end
