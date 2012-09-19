# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cappet/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ['Joseph Pearson']
  gem.email = ['joseph@booki.sh']
  gem.description = 'Unite Capistrano and Puppet config in one Ruby file.'
  gem.summary = 'Cappet Capistrano/Puppet extension'
  gem.homepage = ''

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.name = 'cappet'
  gem.require_paths = ['lib']
  gem.version = Cappet::VERSION
end
