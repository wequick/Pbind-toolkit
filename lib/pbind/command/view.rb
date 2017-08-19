require 'xcodeproj'
require 'pathname'
require 'fileutils'

module Pbind
  class Command
    class View < Command
      self.abstract_command = false
      self.summary = 'Generate the objective-c view code from Pbind layout.'
      self.description = <<-DESC
        This will parse the `PLIST` file and translate it to objective-c code.
      DESC

      self.arguments = [
        CLAide::Argument.new(%(PLIST), true),
      ]

      def initialize(argv)
        super
        @plist = argv.shift_argument
      end

      def validate!
        help! 'The plist is required.' unless @plist
        help! 'The plist is not exists.' unless File.exists?(@plist)
      end

      def run
        parse_plist(@plist)
        super
      end

      private

      #----------------------------------------#

      # !@group Private helpers

      # Parse the plist and generate code
      #
      # @return [void]
      #
      def parse_plist(plist_path)
        plist = Xcodeproj::Plist.read_from_path(plist_path)
        names = []
        parents = []
        
        puts '// Create views'
        plist["views"].each { |name, view|
          clazz = view['clazz']
          properties = view['properties']

          puts "#{clazz} *#{name} = [[#{clazz} alloc] init]; {"

          properties.each { |key, value|
            puts "    #{name}.#{key} = [PBValueParser valueWithString:@\"#{value}\"];"
          }
          puts "    [self addSubview:#{name}];"

          puts '}'
          names.push name
        }

        puts ''
        puts '// Auto layout'
        puts 'NSDictionary *views = @{'
        names.each { |name|
          puts "    @\"#{name}\": #{name},"
        }
        puts '};'
        puts 'NSArray *formats = @['
        plist["formats"].each { |format|
          puts "    @\"#{format}\","
        }
        puts "];"
        puts <<-CODE
for (NSString *format in formats) {
    NSArray *constraints = [PBLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views];
    [view addConstraints:constraints];
}
CODE
      end

    end
  end
end