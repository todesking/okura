Gem::Specification.new do |s|
  s.name        = 'okura'
  s.summary     = "Pure ruby morpheme analyzer"
  s.description = "Pure ruby morpheme analyzer, using MeCab format dic"
  s.authors     = ["@todesking"]
  s.email       = 'discommunicative@gmail.com'
  s.homepage    = 'https://github.com/todesking/okura'

  s.add_development_dependency 'rake', ['>= 0.9.2']
  s.add_development_dependency 'rspec', ['~> 2.7.0']
  s.add_development_dependency 'simplecov', ['~> 0.5.4']

  s.version     = '0.0.1'
  s.files       = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.bindir      = 'bin'
  s.executables = %w(okura)
end
