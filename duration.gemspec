# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'duration/version'

Gem::Specification.new do |gem|
  gem.name          = 'iso-duration'
  gem.version       = Duration::VERSION
  gem.authors       = ['Alexey Ovchinnikov']
  gem.email         = ['alexiss@cybernetlab.ru']
  gem.description   = %q{describes time duration}
  gem.summary       = %q{describes time duration, conformed to ISO-8601 2004}
  gem.homepage      = 'https://github.com/cybernetlab/duration'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'support'
  
  gem.add_development_dependency 'rspec'
end
