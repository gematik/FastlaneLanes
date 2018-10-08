# Note: This action proxies the SPM package command for fastlane

module Fastlane
  module Actions
    class SwiftpackageAction < Action
      def self.run(params)
        cmd = ["swift package"]

        cmd << (generate_commands.include?(params[:command]) ? params[:command] : "")
        cmd << "--build-path #{params[:build_path]}" if params[:build_path]
        cmd << "--package-path #{params[:package_path]}" if params[:package_path]
        cmd << "--xcconfig-overrides #{params[:xcconfig_overrides]}" if params[:xcconfig_overrides]
        cmd << "--configuration #{params[:configuration]}" if params[:configuration]
        cmd << "--verbose" if params[:verbose]
        if params[:xcpretty_output]
          cmd += ["2>&1", "|", "xcpretty", "--#{params[:xcpretty_output]}"]
          cmd = %w(set -o pipefail &&) + cmd
        end
        cmd << params[:command] if !generate_commands.include?(params[:command])

        FastlaneCore::CommandExecutor.execute(command: cmd.join(" "),
                                              print_all: true,
                                              print_command: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs Swift Package Manager `package` subcommands on your project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :command,
                                       env_name: "FL_SPM_PACKAGE_COMMAND",
                                       description: "The swift package command (one of: #{available_commands.join(', ')})",
                                       default_value: "generate-xcodeproj",
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid command. Use one of the following: #{available_commands.join(', ')}") unless available_commands.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :xcconfig_overrides,
                                       env_name: "FL_SPM_PACKAGE_XCCONFIG_OVERRIDES",
                                       description: "Specify an xcconfig file that overrides default xcodeproj settings [default: ./Package.xcconfig]",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_path,
                                       env_name: "FL_SPM_BUILD_PATH",
                                       description: "Specify build/cache directory [default: ./.build] - Only when command is not generate-xcodeproj",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :package_path,
                                       env_name: "FL_SPM_PACKAGE_PATH",
                                       description: "Change working directory before any other operation - Only when command is not generate-xcodeproj",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       short_option: "-c",
                                       env_name: "FL_SPM_CONFIGURATION",
                                       description: "Build with configuration (debug|release) [default: debug]",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid configuration: (debug|release)") unless valid_configurations.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :xcpretty_output,
                                       env_name: "FL_SPM_XCPRETTY_OUTPUT",
                                       description: "Specifies the output type for xcpretty. eg. 'test', or 'simple'",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid xcpretty output type: (#{xcpretty_output_types.join('|')})") unless xcpretty_output_types.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       short_option: "-v",
                                       env_name: "FL_SPM_VERBOSE",
                                       description: "Increase verbosity of informational output",
                                       is_string: false,
                                       default_value: false)
        ]
      end

      def self.authors
        ["Adriaan Duijzer (@arjanduz)"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'swiftpackage',
          'swiftpackage(
            command: "generate-xcodeproj",
            xcconfig_overrides: "./Package.xcconfig"
          )'
        ]
      end

      def self.category
        :project
      end

      def self.generate_commands
        %(generate-xcodeproj)
      end

      def self.available_commands
        %w(generate-xcodeproj update)
      end

      def self.xcpretty_output_types
        %w(simple test knock tap)
      end
    end
  end
end
