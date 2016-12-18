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

        if !@changed
          puts 'All are UP-TO-DATE.'
        end
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
          file_refs = Array.new
          Dir.foreach(@api_install_dir) do |file|
            if !File.directory?(file)
              file_refs << group.new_reference(File.join(@api_install_dir, file))
            end
          end
          target.add_file_references(file_refs)
          changed = true
        end

        # Create directory
        client_dir = File.join(@api_install_dir, @client)
        if !File.exists?(client_dir)
          Dir.mkdir client_dir
          changed = true
        end

        # Create json file
        json_path = File.join(client_dir, "#{@action}.json")
        if !File.exists?(json_path)
          json_file = File.new(json_path, 'w')
          json_file.puts("{\n  \n}")
          changed = true
        end

        # Add json file reference
        group = group.find_subpath(@client, true)
        if group.empty?
          group.clear
          file_refs = Array.new
          file_refs << group.new_reference(json_path)
          target.add_file_references(file_refs)
          changed = true
        end

        # Save
        if !changed
          return
        end

        UI.section("Creating PBLocalhost/#{@client}/#{@action}.json.") do
          project.save
          @changed = true
        end
      end
    end
  end
end