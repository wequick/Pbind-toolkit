require 'xcodeproj'
require 'pathname'
require 'fileutils'

module Pbind
  class Command
    class Watch < Command
      self.summary = 'Enable Pbind can watch sources and apply instant changes at runtime.'
      self.description = <<-DESC
        1. Download `PBPlayground` sources from GitHub, create a new group named `PBPlayground` and add it to the current project.

        2. Modify the project `Info.plist` and set `PBResourcesPath` to `$(SRCROOT)/[project_name]`, `PBLocalhost` to `$(SRCROOT)/PBLocalhost`.

        3. At runtime: `[PBPlayground load]` observe the application lifecycle and watch the above paths to apply instant changes. 
      DESC

      self.arguments = [
        CLAide::Argument.new('XCODEPROJ', true),
      ]

      def initialize(argv)
        @project_path = argv.shift_argument
      end

      def validate!
        # super
        help! 'A path for the xcodeproj is required.' unless @project_path
        @project_path = @project_path.chomp('/')
        help! 'The xcodeproj path should ends with ".xcodeproj"' unless @project_path.end_with?('.xcodeproj')
        help! "The xcodeproj path '#{@project_path}' is not exists." unless File.exists?(@project_path) 
      end

      def run
        @src_name = 'PBPlayground'
        @api_name = 'PBLocalhost'
        @src_key = 'PBResourcesPath'
        @project_root = File.dirname(@project_path)
        @src_install_dir = File.absolute_path(File.join(@project_root, @src_name))
        @api_install_dir = File.absolute_path(File.join(@project_root, @api_name))
        @project = Xcodeproj::Project.open(@project_path)
        @changed = false

        install_sources
        add_plist_entries
        add_group_references

        if !@changed
          puts 'All are UP-TO-DATE.'
        end
      end

      private

      #----------------------------------------#

      # !@group Private helpers

      # Install the `PBPlayground`, `PBLocalhost` sources
      #
      # @return [void]
      #
      def install_sources
        if File.exists?(@src_install_dir)
          return
        end

        source_dir = ENV['PBIND_SOURCE']
        UI.section("Copying `#{source_dir}` into `#{@project_root}`.") do
          FileUtils.cp_r File.join(source_dir, @src_name), @project_root
          FileUtils.cp_r File.join(source_dir, @api_name), @project_root
          @changed = true
        end
      end

      # Add the source path to `Info.plist`
      #
      # @return [Bool] something changed
      #
      def add_plist_entries
        project = @project
        target = project.targets.first

        source_root = File.join('$(SRCROOT)', target.name)
        api_root = File.join('$(SRCROOT)', @api_name)

        debug_cfg = target.build_configurations.detect { |e| e.name == 'Debug' }
        info_plist = debug_cfg.build_settings['INFOPLIST_FILE']

        info_plist_path = File.join(@project_root, info_plist)
        if !File.exists?(info_plist_path)
          puts "Failed to find `#{info_plist_path}`".red
          return
        end

        changed = false
        plist = Xcodeproj::Plist.read_from_path(info_plist_path)
        if (plist[@src_key] != source_root)
          plist[@src_key] = source_root
          changed = true
        end
        if (plist[@api_name] != api_root)
          plist[@api_name] = api_root
          changed = true
        end

        if !changed
          return
        end

        UI.section("Add plist entires to `#{@project_path}`.") do
          Xcodeproj::Plist.write_to_path(plist, info_plist_path)
          @changed = true
        end
      end

      # Add `PBPlayground`, `PBLocalhost` group references to the project
      #
      # @return [Bool] something changed
      #
      def add_group_references
        project = @project
        target = project.targets.first
        changed = false

        # Add PBPlayground group
        group = project.main_group.find_subpath(@src_name, true)
        if group.empty?
          group.set_source_tree('SOURCE_ROOT')
          file_refs = Array.new
          Dir.foreach(@src_install_dir) do |file|
            if !File.directory?(file)
              file_refs << group.new_reference(File.join(@src_install_dir, file))
            end
          end
          target.add_file_references(file_refs)
          changed = true
        end

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

        # Save
        if !changed
          return
        end

        UI.section("Add group [`#{@src_name}`, `#{@api_name}`] to `#{@project_path}`.") do
          project.save
          @changed = true
        end
      end
    end
  end
end