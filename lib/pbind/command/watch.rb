require 'xcodeproj'
require 'pathname'
require 'fileutils'

module Pbind
  class Command
    class Watch < Command
      self.abstract_command = false
      self.summary = 'Enable the live load feature for Pbind.'
      self.description = <<-DESC
        Downloads all dependencies of `PBLiveLoader` for the Xcode project.

        The Xcode project file should be specified in `--project` like this:

            --project=path/to/Project.xcodeproj

        If no project is specified, then a search for an Xcode project will be made. If
        more than one Xcode project is found, the command will raise an error.

        This will configure the project to reference the Pbind LiveLoader library
        and add a PBLocalhost directory for later JSON mocking. 
      DESC

      def validate!
        verify_project_exists
      end

      def run
        @src_name = 'PBLiveLoader'
        @api_name = 'PBLocalhost'
        @src_key = 'PBResourcesPath'
        @project_root = File.dirname(@project_path)
        @src_install_dir = File.absolute_path(File.join(@project_root, @src_name))
        @api_install_dir = File.absolute_path(File.join(@project_root, @api_name))
        @project = Xcodeproj::Project.open(@project_path)
        @changed = false

        install_sources
        # add_plist_entries
        add_group_references

        super
      end

      private

      #----------------------------------------#

      # !@group Private helpers

      # Install the `PBLiveLoader`, `PBLocalhost` sources
      #
      # @return [void]
      #
      def install_sources
        source_dir = ENV['PBIND_SOURCE']
        src_dir = File.join(source_dir, @src_name)

        if !File.exists?(@src_install_dir)
          UI.section("Copying `#{@src_name}` into `#{@project_root}`") do
            FileUtils.cp_r src_dir, @project_root
            @changed = true
          end
        else
          # Check for upgrade.
          Dir.foreach(@src_install_dir) do |filename|
            if File.directory?(filename)
              next
            end

            src_file = File.join(src_dir, filename)
            if !File.exists?(src_file)
              next
            end
            
            dst_file = File.join(@src_install_dir, filename)
            src_md5 = Digest::MD5.hexdigest( File.open(src_file, "rb"){|fs| fs.read} )
            dst_md5 = Digest::MD5.hexdigest( File.open(dst_file, "rb"){|fs| fs.read} )
            if src_md5 != dst_md5
              UI.section("Upgrading `#{@src_name}/#{filename}`") do
                FileUtils.cp src_file, dst_file
                @changed = true
              end
            end
          end
        end

        src_dir = File.join(source_dir, @api_name)

        if !File.exists?(@api_install_dir)
          UI.section("Copying `#{@api_name}` into `#{@project_root}`") do
            FileUtils.cp_r src_dir, @project_root
            @changed = true
          end
        else
          # Check for upgrade.
          Dir.foreach(@api_install_dir) do |filename|
            if File.directory?(filename)
              next
            end

            src_file = File.join(src_dir, filename)
            if !File.exists?(src_file)
              next
            end

            dst_file = File.join(@api_install_dir, filename)
            src_md5 = Digest::MD5.hexdigest(File.open(src_file, "rb"){|fs| fs.read} )
            dst_md5 = Digest::MD5.hexdigest(File.open(dst_file, "rb"){|fs| fs.read} )
            if src_md5 != dst_md5
              UI.section("Upgrading `#{@api_name}/#{filename}`") do
                FileUtils.cp src_file, dst_file
                @changed = true
              end
            end
          end
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

        UI.section("Adding plist entires to `#{@project_path}`") do
          Xcodeproj::Plist.write_to_path(plist, info_plist_path)
          @changed = true
        end
      end

      # Add `PBLiveLoader`, `PBLocalhost` group references to the project
      #
      # @return [Bool] something changed
      #
      def add_group_references
        project = @project
        target = project.targets.first
        changed = false

        # Add PBLiveLoader group
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

        UI.section("Adding group references to `#{@project_path}`") do
          project.save
          @changed = true
        end
      end
    end
  end
end