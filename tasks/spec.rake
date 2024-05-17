require 'rspec/core/rake_task'

spec_defaults = lambda do |spec|
  spec.pattern    = 'spec/**/*_spec.rb'
end

begin
  task(:default).clear
  task(:spec).clear

  RSpec::Core::RakeTask.new(:spec, &spec_defaults)
rescue LoadError
  task :spec do
    abort 'rspec is not available. In order to run spec, you must: gem install rspec'
  end
end

begin
  require 'rcov'
  require 'spec/rake/verify_rcov'

  RSpec::Core::RakeTask.new(:rcov) do |rcov|
    rcov.pattern    = './spec/**/*_spec.rb'
    rcov.rcov       = true
    rcov.rcov_opts  = File.read('spec/rcov.opts').split(/\s+/)
  end

  RCov::VerifyTask.new(:verify_rcov => :rcov) do |rcov|
    rcov.threshold = 100
  end
rescue LoadError
  %w(rcov verify_rcov).each do |name|
    task name do
      abort "rcov is not available. In order to run #{name}, you must: gem install rcov"
    end
  end
end

task default: :spec
