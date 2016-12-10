require 'colored'
require 'claide'

module Pbind
  class Command < CLAide::Command

    require_relative 'command/watch'
    require_relative 'command/mock'

    self.abstract_command = true
    self.command = 'pbind'
    self.version = version
    self.description = 'Pbind, the Pbind xcode project helper.'
    self.plugin_prefixes = %w(claide pbind)

    def self.report_error(exception)
      case exception
      when Interrupt
        puts ''
        puts '[!] Cancelled'.red
        # Config.instance.verbose? ? raise : exit(1)
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

  end
end