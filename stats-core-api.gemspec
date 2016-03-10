Gem::Specification.new do |s|
  s.name        = 'stats-core-api'
  s.version     = "0.1.11"
  s.date        = '2013-11-27'
  s.summary     = "stats core api"
  s.description = "stats core api"
  s.authors     = ["nX8igTYAm2iskVhn"]
  s.email       = 'hashu@nX8igTYAm2iskVhn.com'
  s.homepage    =
    'https://github.nX8igTYAm2iskVhndev.com/nX8igTYAm2iskVhn/gem-stats-core'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
