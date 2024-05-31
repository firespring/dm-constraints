require 'pathname'

source 'https://rubygems.org'

gemspec

SOURCE         = ENV.fetch('SOURCE', :git).to_sym
REPO_POSTFIX   = (SOURCE == :path) ? '' : '.git'
DATAMAPPER     = (SOURCE == :path) ? Pathname(__FILE__).dirname.parent : 'https://github.com/firespring'
DM_VERSION     = '~> 1.3.0.beta'.freeze
DO_VERSION     = '~> 0.10.17'.freeze
DM_DO_ADAPTERS = %w(sqlite postgres mysql oracle sqlserver).freeze
CURRENT_BRANCH = ENV.fetch('GIT_BRANCH', 'master')

if SOURCE == :path
  gem 'dm-core', DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-core#{REPO_POSTFIX}"
else
  gem 'dm-core', DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-core#{REPO_POSTFIX}", branch: CURRENT_BRANCH
end

platforms :mri_18 do
  group :quality do
    gem 'rcov'
    gem 'yard'
    gem 'yardstick'
  end
end

# development dependencies
group :development do
  gem 'rake'
  gem 'rspec'
end

group :datamapper do
  adapters = ENV['ADAPTER'] || ENV.fetch('ADAPTERS', nil)
  adapters = adapters.to_s.tr(',', ' ').split.uniq - %w(in_memory)

  if (do_adapters = DM_DO_ADAPTERS & adapters).any?
    do_options = {}
    do_options[:git] = "#{DATAMAPPER}/datamapper-do#{REPO_POSTFIX}" if ENV['DO_GIT'] == 'true'

    gem 'data_objects', DO_VERSION, do_options.dup

    do_adapters.each do |adapter|
      adapter = 'sqlite3' if adapter == 'sqlite'
      gem "do_#{adapter}", DO_VERSION, do_options.dup
    end

    if SOURCE == :path
      gem 'dm-do-adapter', DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-do-adapter#{REPO_POSTFIX}"
    else
      gem 'dm-do-adapter', DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-do-adapter#{REPO_POSTFIX}", branch: CURRENT_BRANCH
    end
  end

  adapters.each do |adapter|
    if SOURCE == :path
      gem "dm-#{adapter}-adapter", DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-#{adapter}-adapter#{REPO_POSTFIX}"
    else
      gem "dm-#{adapter}-adapter", DM_VERSION, SOURCE => "#{DATAMAPPER}/dm-#{adapter}-adapter#{REPO_POSTFIX}", branch: CURRENT_BRANCH
    end
  end

  plugins = ENV['PLUGINS'] || ENV.fetch('PLUGIN', nil)
  plugins = plugins.to_s.tr(',', ' ').split.push('dm-migrations').uniq

  plugins.each do |plugin|
    if SOURCE == :path
      gem plugin, DM_VERSION, SOURCE => "#{DATAMAPPER}/#{plugin}#{REPO_POSTFIX}"
    else
      gem plugin, DM_VERSION, SOURCE => "#{DATAMAPPER}/#{plugin}#{REPO_POSTFIX}", branch: CURRENT_BRANCH
    end
  end
end
