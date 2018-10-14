module Circleci
  module Bundle
    module Update
      module Pr
        module Note
          module_function

          def exist?
            File.exist?('.circleci/BUNDLE_UPDATE_NOTE.md') ||
              File.exist?('CIRCLECI_BUNDLE_UPDATE_NOTE.md')
          end

          def read
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
