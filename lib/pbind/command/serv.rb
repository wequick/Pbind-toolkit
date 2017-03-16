require 'xcodeproj'
require 'pathname'
require 'fileutils'
require 'listen'

require 'webrick'
include WEBrick

module Pbind
  class Command
    class Serv < Command
      self.abstract_command = false
      self.summary = 'Start a mock server for device.'
      self.description = <<-DESC
        This will start a HTTP server provides the APIs in PBLocalhost and
        also a Socket server to send file changes to the device. 
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

        listen_file_changes
        open_tcp_server

        trap("SIGINT") {
          @server.close
          @listener.stop
          exit
        }

        super
        # sleep
      end

      private

      #----------------------------------------#

      # !@group Private helpers

      # Create a HTTP server and open it
      #
      # @return [void]
      #
      def open_tcp_server
        require 'socket'

        server = TCPServer.new 8082 # Server bind to port
        @server = server
        @clients = []

        addr = server.addr
        addr.shift
        puts "server is on #{addr.join(':')}"

        loop do
          Thread.start(server.accept) do |client|
            @clients.push client
            loop do
              line = client.readpartial(1024)
              if line != nil and line.end_with?('.json')
                send_json(@clients, line)
              end
            end
            client.close
          end
        end

        # loop do
        #   client = server.accept    # Wait for a client to connect
        #   @client = client

        #   line = client.readpartial(1024)
        #   puts "get #{line}"
        #   if line != nil and line.end_with?('.json')
        #     puts "send #{line}"
        #     send_json(client, line)
        #   end

        #   client.close
        # end
      end

      def listen_file_changes
        @listener = Listen.to(@project_root) do |modified, added, removed|
          # puts "modified absolute path: #{modified}"
          # puts "added absolute path: #{added}"
          # puts "removed absolute path: #{removed}"

          modified.each { |m|
            if m.end_with?('.plist')
              if @clients != nil
                send_plist @clients, m
              end
            elsif m.end_with?('.json')
              if @clients != nil
                send_file_update @clients, m, nil
              end
            end
          }
        end

        @listener.start # not blocking
      end

      def send_json(clients, json_file)
        file = File.open(File.join(@api_install_dir, json_file), "r")
        content = file.read
        file.close

        UI.section("Send API \"/#{File.basename(json_file, '.json')}\"") {
          clients.each { |client|
            write_byte   client, 0xE0
            write_string client, content
          }
        }
      end

      def send_plist(clients, plist_path)
        # Create a binary plist
        require 'tempfile'
        plist_name = File.basename(plist_path)
        temp = Tempfile.new(plist_name)
        `plutil -convert binary1 #{plist_path} -o #{temp.path}`

        send_file_update clients, temp.path, plist_name
      end

      def send_file_update(clients, file_path, file_name)
        File.open(file_path, "r") { |file|
          file_content = file.read
          if file_name == nil
            file_name = File.basename(file_path)
          end
          UI.section("Update file \"#{file_name}\"") {
            clients.each { |client|
              write_byte(client, 0xF1)
              write_string(client, file_name)
              write_string(client, file_content)
            }
          }
        }
      end

      def write_byte(client, b)
        write_any client, [b].pack("C")
      end

      def write_string(client, text)
        write_any client, [text.bytesize].pack("N")
        write_any client, text
      end

      def write_any(client, obj)
        begin
          client.write obj
        rescue Exception => e
          @clients.delete client
        end
      end

    end
  end
end