#
#  Copyright (c) 2019 gematik - Gesellschaft für Telematikanwendungen der Gesundheitskarte mbH
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#     http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require 'xcodeproj'

module Fastlane
  module Actions
    class BuildsettingAction < Action
      def self.run(params)
        projectPath = params[:project]
        project = Xcodeproj::Project.open(projectPath)

        if params[:command] == 'modulemap'
          modulemap(project, params)
        end

        project.save
      end

      def self.modulemap(project, params)
        sdkroot = params[:sdkroot]
        static = params[:type] == 'static'
        project.targets.each do |target|
          projectBase = File.basename(project.path)
          module_map_file = "#{projectBase}/GeneratedModuleMap/#{target.name}/module.modulemap"

          target.build_configurations.each do |config|
            config.build_settings['DEFINES_MODULE'] = 'YES'
            if !sdkroot.nil?
              config.build_settings['SDKROOT'] = sdkroot
            else
              config.build_settings['SDKROOT'] = 'iphoneos'
            end

            # Remove this line if you prefer to link the dependencies dynamically
            # You will also need to embed the framework with the app bundle
            if static
              config.build_settings['MACH_O_TYPE'] = 'staticlib'
            end

            # Set MODULEMAP_FILE for non-Swift Frameworks
            #
            # Module maps are correctly generated for non-Swift frameworks, but SPM
            # doesn't put the path in the build config output from generate-xcodeproj.
            if File.exist? module_map_file
              config.build_settings['MODULEMAP_FILE'] = "${SRCROOT}/#{module_map_file}"
            end
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Add/Change Xcodeproj build setting(s)"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :command,
                                       env_name: "BUILD_SETTING_COMMAND",
                                       description: "The xcodeproj build-setting group (one of: #{available_commands.join(', ')})",
                                       default_value: "modulemap",
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid command. Use one of the following: #{available_commands.join(', ')}") unless available_commands.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :project,
                                       env_name: "BUILD_SETTING_PROJECT_PATH",
                                       description: "Specify an Xcodeproj path",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :type,
                                       env_name: "BUILD_SETTING_TYPE",
                                       description: "Type (one of: #{available_types.join(', ')})",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid type. Use one of the following: #{available_types.join(', ')}") unless available_types.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :sdkroot,
                                       env_name: "BUILD_SETTING_SDKROOT",
                                       description: "Value for SDKROOT (E.g. iphoneos, iphonesimulator)",
                                       optional: true)
        ]
      end

      def self.authors
        ["Adriaan Duijzer (@nxtstep)"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'buildsetting',
          'buildsetting(
            command: "modulemap",
            project: "Dependencies.xcodeproj",
            type: "static",
            sdkroot: "iphoneos"
          )'
        ]
      end

      def self.category
        :project
      end

      def self.available_commands
        %w(modulemap)
      end

      def self.available_types
        %w(static dynamic)
      end
    end
  end
end
