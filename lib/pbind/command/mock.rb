require 'xcodeproj'
require 'pathname'
require 'fileutils'

module Pbind
  class Command
    class Mock < Command
      self.summary = 'Enable JSON mocking feature for Pbind.'
      self.description = <<-DESC
        Create `CLIENT`/`ACTION`.json under PBLocalhost directory for the XCODEPROJ. 
      DESC

      self.arguments = [
        CLAide::Argument.new(%(CLIENT ACTION), true),
      ]

      def initialize(argv)
        super
        @client = argv.shift_argument
        @action = argv.shift_argument
      end

      def validate!
        verify_project_exists
        help! 'The client is required.' unless @client
        help! 'The action is required.' unless @action
      end

      def run
        @api_name = 'PBLocalhost'
        @project_root = File.dirname(@project_path)
        @api_install_dir = File.absolute_path(File.join(@project_root, @api_name))
        @project = Xcodeproj::Project.open(@project_path)
        @changed = false

        add_mock_json

        super
      end

      private

      #----------------------------------------#

      # !@group Private helpers

      # Create [CLIENT]/[ACTION].json under PBLocalhost directory
      #
      # @return [void]
      #
      def add_mock_json
        project = @project
        target = project.targets.first
        changed = false

        # Add PBLocalhost group
        group = project.main_group.find_subpath(@api_name, true)
        if group.empty?
          group.clear
          UI.section("Create group \"PBLocalhost\"") do
            file_refs = Array.new
            Dir.foreach(@api_install_dir) do |file|
              if !File.directory?(file)
                file_refs << group.new_reference(File.join(@api_install_dir, file))
              end
            end
            target.add_file_references(file_refs)
            changed = true
          end
        end

        # Create directory
        client_dir = File.join(@api_install_dir, @client)
        if !File.exists?(client_dir)
          Dir.mkdir client_dir
          changed = true
        end

        # Create json file
        json_name = "#{@action}.json"
        json_path = File.join(client_dir, json_name)
        json_relative_path = "PBLocalhost/#{@client}/#{json_name}"
        if !File.exists?(json_path)
          UI.section("Creating file `#{json_relative_path}`") do
            json_file = File.new(json_path, 'w')
            json_file.print("{\n  \n}")
            changed = true
          end
        end

        # Add json file reference
        group = group.find_subpath(@client, true)
        added = true
        if group.empty?
          group.clear
          added = false
        else
          found = group.files.index {|x| x.path==json_relative_path}
          if found == nil
            added = false
          end
        end

        if !added
          file_refs = Array.new
          file_refs << group.new_reference(json_path)
          target.add_file_references(file_refs)
          changed = true
        end

        if !changed
          return
        end

        # Save
        UI.section("Adding reference `#{json_relative_path}`") do
          project.save
          @changed = true
        end
      end
    end
  end
end