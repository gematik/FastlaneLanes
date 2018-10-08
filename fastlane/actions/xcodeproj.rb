# Note: This action proxies the xcodeproj ruby gem commands for fastlane

require 'xcodeproj'

module Fastlane
  module Actions
    class XcodeprojAction < Action
      def self.run(params)
        verbose = (params[:verbose] ? true : false)

        # Load project
        projectPath = params[:project]
        outputPath = (params[:output] ? params[:output] : projectPath)
        puts "Project: #{projectPath} >> #{outputPath}" if verbose
        project = Xcodeproj::Project.open(projectPath)

        # Find the group
        group = params[:group].split('/').reduce(project) { |groupc, name| groupc[name] }
        puts "  *Group: #{group}" if verbose
        UI.user_error!("Group: [#{params[:group]}] could not be found in project [#{projectPath}]. Please specify an existing group.")  unless group != nil

        # Select target
        target = project.targets.select { |target| target.name == params[:target] }.first
        puts "  Target: #{target}" if verbose
        UI.user_error!("Target: [#{params[:target]}] could not be found in project [#{projectPath}]. Please specify an existing target.")  unless target != nil
        # Add (TODO REMOVE)
        params[:resources].each do |file|
          puts "    resource build phase: #{file}" if verbose
          fileRef = group.new_reference(file)
          target.resources_build_phase.add_file_reference(fileRef, true)
        end unless params[:resources] == nil

        project.save(outputPath)
        puts "Saved project changes >> #{outputPath}" if verbose
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Add/Remove items/groups/targets/build phases to your Xcodeproj file"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :command,
                                       env_name: "FL_XCODEPROJ_COMMAND",
                                       description: "The xcodeproj command (one of: #{available_commands.join(', ')})",
                                       default_value: "add",
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid command. Use one of the following: #{available_commands.join(', ')}") unless available_commands.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :project,
                                       env_name: "FL_XCODEPROJ_PROJECT_PATH",
                                       description: "Specify an Xcodeproj path",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: "FL_XCODEPROJ_TARGET",
                                       description: "Specify an existing target in the project. You can find available targets with `xcodebuild -project ${xcodeproject_path} -list`",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :group,
                                       env_name: "FL_XCODEPROJ_GROUP",
                                       description: "Specify an existing project group. E.g. [Tests/Assets]",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :resources,
                                       env_name: "FL_XCODEPROJ_RESOURCES_BUILD_PHASE",
                                       description: "List of files/bundles to add to the target",
                                       type: Array,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :output,
                                       env_name: "FL_XCODEPROJ_OUTPUT_PATH",
                                       description: "The project output path. [default: :project]",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       short_option: "-v",
                                       env_name: "FL_XCODEPROJ_VERBOSE",
                                       description: "Increase verbosity of informational output",
                                       type: Boolean,
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
          'xcodeproj',
          'xcodeproj(
            command: "add",
            project: "./CardSimulationLoader.xcodeproj",
            target: "CardSimulationLoaderTests",
            group: "Tests/CardSimulationLoaderTests",
            resources: [
              "./Tests/CardSimulationLoaderTests/Resources.bundle"
            ],
            output: "./MyModified.xcodeproj"
          )'
        ]
      end

      def self.category
        :project
      end

      def self.available_commands
        %w(add remove)
      end
    end
  end
end
