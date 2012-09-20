# -*- encoding: utf-8 -*-
require File.expand_path('../lib/hubcap/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ['Joseph Pearson']
  gem.email = ['joseph@booki.sh']
  gem.description = 'Unite Capistrano and Puppet config in one Ruby file.'
  gem.summary = 'Hubcap Capistrano/Puppet extension'
  gem.homepage = ''

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.name = 'hubcap'
  gem.require_paths = ['lib']
  gem.version = Hubcap::VERSION
end
