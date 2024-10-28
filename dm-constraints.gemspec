require File.expand_path('../lib/data_mapper/constraints/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors     = ['opensource_firespring']
  gem.email       = ['opensource@firespring.com']
  gem.summary     = 'DataMapper plugin constraining relationships'
  gem.description = 'Plugin that adds foreign key constraints to associations. Currently supports only PostgreSQL and MySQL ' \
                    'All constraints are added to the underlying database, but constraining is implemented in pure ruby.'
  gem.license = 'Nonstandard'
  gem.homepage = 'https://datamapper.org'

  gem.files            = `git ls-files`.split("\n")
  gem.extra_rdoc_files = %w(LICENSE README.rdoc)

  gem.name          = 'sbf-dm-constraints'
  gem.require_paths = ['lib']
  gem.version       = DataMapper::Constraints::VERSION
  gem.required_ruby_version = '>= 2.7.8'

  gem.add_runtime_dependency('sbf-dm-core', '~> 1.3.0.beta')
end
