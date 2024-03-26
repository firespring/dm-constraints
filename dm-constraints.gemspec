require File.expand_path('../lib/data_mapper/constraints/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors     = ['Dirkjan Bussink']
  gem.email       = ['d.bussink [a] gmail [d] com']
  gem.summary     = 'DataMapper plugin constraining relationships'
  gem.description = gem.summary
  gem.homepage    = 'https://datamapper.org'

  gem.files            = `git ls-files`.split("\n")
  gem.extra_rdoc_files = %w(LICENSE README.rdoc)

  gem.name          = 'dm-constraints'
  gem.require_paths = ['lib']
  gem.version       = DataMapper::Constraints::VERSION
  gem.required_ruby_version = '>= 2.7.8'

  gem.add_runtime_dependency('dm-core', '~> 1.3.0.beta')

end
