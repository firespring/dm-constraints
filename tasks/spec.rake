require 'rspec/core/rake_task'

begin
  task(:default).clear
  task(:spec).clear

  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'

    require 'simplecov'
    SimpleCov.start do
      minimum_coverage 100
    end
  end
rescue LoadError
  task :spec do
    abort 'rspec is not available. In order to run spec, you must: gem install rspec'
  end
end

task default: :spec
