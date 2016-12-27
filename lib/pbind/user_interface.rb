module Pbind
  module UI

    require "colored"

    class << self

      def section(title)
        message = "%-64s" % title
        print message.yellow

        yield if block_given?

        puts '[  OK  ]'.green
      end

      def notice(message)
        puts ''
        puts "[!] #{message}".green
      end
    end
  end
end