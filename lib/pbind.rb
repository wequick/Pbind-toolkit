require 'rubygems'
require 'xcodeproj'

module Pbind
  require_relative 'pbind/command'
end

# class Pbind
    
#     install_dir = 'PBPlayground'

#     # project.targets.each do |target|
#     #   puts target.name
#     # end

#     # target = project.targets.first
#     # files = target.source_build_phase.files.to_a.map do |pbx_build_file|
#     #   pbx_build_file.file_ref.real_path.to_s

#     # end.select do |path|
#     #   path.end_with?(".m", ".mm", ".swift")

#     # end.select do |path|
#     #   File.exists?(path)
#     # end

#     # puts files

#     define_method :downloadSource do
#         if File.exists?(install_dir)
#             return true
#         end

#         `curl -OL https://github.com/wequick/Pbind/releases/download/0.6.0/PBPlayground.zip && tar -xvf PBPlayground.zip && rm PBPlayground.zip`
#         return File.exists?(install_dir)
#     end

#     define_method :addReferences do |project_path|
#         project = Xcodeproj::Project.open(project_path)
#         target = project.targets.first

#         group = project.main_group.find_subpath(install_dir, true)
#         group.set_source_tree('SOURCE_ROOT')
#         group.clear

#         file_refs = Array.new
#         Dir.foreach(install_dir) do |file|
#             if !File.directory?(file)
#                 file_refs << group.new_reference(File.join(install_dir, file))
#             end
#         end

#         target.add_file_references(file_refs)  
#         project.save
#     end

#     def logSuccess
#         puts "[  \e[32mOK\e[0m  ]"
#     end

#     def logFailed
#         puts "[\e[31mFAILED\e[0m]"
#     end

#     define_method :install do
#         project_paths = Dir.glob("*.xcodeproj")
#         if project_paths.empty?
#             puts "Failed to find any xcodeproj!"
#             return
#         end

#         project_path = project_paths[0]
#         print '%-64s' % 'Downloading PBPlayground source...'
#         ret = downloadSource
#         if !ret
#             logFailed
#             return
#         end
#         logSuccess

#         print '%-64s' % 'Add PBPlayground reference to project...'
#         addReferences project_path
#         logSuccess
#     end

#     def self.hi
#         puts "Hello world!"
#     end

#     def self.exec argv
#         puts "Hello #{argv[0]}"
#     end
# end