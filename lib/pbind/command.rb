require 'colored'
require 'claide'

require 'cocoapods/config'
require 'cocoapods/user_interface'

module Pbind
  class Command < CLAide::Command

    require_relative 'command/watch'
    require_relative 'command/mock'

    self.abstract_command = true
    self.command = 'pbind'
    self.version = version
    self.description = 'Pbind, the Pbind XcodeProject Helper.'
    self.plugin_prefixes = %w(claide pbind)

    UI = Pod::UI

    def self.report_error(exception)
      case exception
      when Interrupt
        puts ''
        puts '[!] Cancelled'.red
      when SystemExit
        raise
      else
        # if ENV['PBIND_ENV'] != 'development'
        #   puts UI::ErrorReport.report(exception)
        #   UI::ErrorReport.search_for_exceptions(exception)
        #   exit 1
        # else
          raise exception
        # end
      end
    end

    def self.options
      [
        ['--project=path/to/Project.xcodeproj', 'The path of the XcodeProject.']
      ].concat(super)
    end

    def initialize(argv)
      super

      @project_path = argv.option('project')
    end

    def run
      if !@changed
        UI.notice 'All are UP-TO-DATE.'
      end
    end

    def verify_project_exists
      if @project_path == nil
        projects = Dir.glob("*.xcodeproj")
        num_project = projects.length

        help! 'No `*.xcodeproj\' found in the project directory.' if num_project == 0
        help! "Could not automatically select an Xcode project. Specify one in your arguments like so:\
        \n\n    --project=path/to/Project.xcodeproj" unless num_project == 1

        @project_path = projects[0]
      else
        help! 'The Xcode project should ends with `*.xcodeproj`.' unless @project_path.end_with?('.xcodeproj')
        absolute_path = File.absolute_path(@project_path)
        help! "Unable to find the Xcode project `#{absolute_path}`." unless File.exists?(absolute_path)
      end
    end

  end
end