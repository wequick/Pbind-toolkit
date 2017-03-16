Gem::Specification.new do |s|
  s.name        = 'pbind'
  s.version     = '0.5.0'
  s.date        = '2016-12-11'
  s.summary     = "Pbind xcodeproj helper"
  s.description = "A toolkit to create a xcode project with Pbind."
  s.authors     = ["Galen Lin"]
  s.email       = 'oolgloo.2012@gmail.com'
  s.files       = Dir["lib/**/*.rb"] + Dir["source/**/*"] + %w{ bin/pbind }
  s.homepage    = 'http://rubygems.org/gems/pbind'
  s.license     = 'MIT'
  s.executables << 'pbind'
  s.add_runtime_dependency 'xcodeproj', '>= 1.3.2', '< 2.0'
  s.add_runtime_dependency 'claide',    '>= 1.0.1', '< 2.0'
  s.add_runtime_dependency 'listen',    '3.1.5'
end
