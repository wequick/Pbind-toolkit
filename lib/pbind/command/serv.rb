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
        @api_ignores_file = File.absolute_path(File.join(@api_install_dir, 'ignore.h'))
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
        @client_names = Hash.new

        addr = server.addr
        addr.shift
        puts "#{'Pbind server is on'.bold} #{local_ip.underline}"

        loop do
          Thread.start(server.accept) do |client|
            @clients.push client
            loop do
              req = client.readpartial(1024)
              if req != nil
                handle_request(client, req)
              end
            end
            client.close
          end
        end
      end

      def handle_request(client, req)
        type = req.bytes[0]
        msg = req[1..-1]

        if type == 0xC0
          # Connected
          @client_names[client] = msg
          print_client_msg(client, "Connected")
        elsif type == 0xC1
          # Request API
          print_client_msg(client, "Request API '#{msg}'")
          send_json([client], msg)
        elsif type == 0xC2
          # Log
          print_client_msg(client, msg)
        elsif type == 0xF1
          print_client_msg(client, "Apply changed '#{msg}'")
        elsif type == 0xD0
          print_client_msg(client, "Got response '#{msg}'")
        end
      end

      def local_ip
        addr_infos = Socket.ip_address_list
        local_addr_info = addr_infos.select { |info|
          info.ipv4? and info.ip_address != '127.0.0.1'
        }
        local_addr_info[0].ip_address
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

      def send_json(clients, api)
        # Check if ignores
        file = File.open(@api_ignores_file, "r")
        file.each_line { |line|
          if line.start_with? '//'
            next
          end

          ignore = line.chomp
          if ignore.include? api
            print_serv_msg "Ignores API '#{api}'"
            clients.each { |client|
              write_byte  client, 0xE0
            }
            return
          end
        }

        # Read content and minify
        json_file = "#{api}.json"
        file = File.open(File.join(@api_install_dir, json_file), "r")
        content = file.read
        file.close

        content = Minify.json(content)

        # Send content
        print_serv_msg("Send API '#{api}'")
        clients.each { |client|
          write_byte   client, 0xD0
          write_string client, api
          write_string client, content
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

          print_serv_msg("Update file \"#{file_name}\"")
          clients.each { |client|
            write_byte(client, 0xF1)
            write_string(client, file_name)
            write_string(client, file_content)
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

      def print_serv_msg(msg)
        print_time
        print "[Pbind] ".yellow
        puts msg
      end

      def print_client_msg(client, msg)
        print_time
        device = @client_names[client]
        if (device == nil)
          device = "unknown"
        end
        print "[#{device}] ".green
        puts msg
      end

      def print_time
        t = Time.now
        print t.strftime("%H:%M:%S")
        print '.'
        print '%03d' % ((t.to_f * 1000).to_i % 1000) # ms
        print ' '
      end

    end
  end
end