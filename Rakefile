require 'bundler/gem_tasks'
task default: [:lint, :spec]

require 'rubocop/rake_task'
desc 'Run rubocop'
RuboCop::RakeTask.new(:lint) do |t|
  t.requires << 'rubocop-rspec'
end

require 'rspec/core/rake_task'
desc 'Run spec tests using rspec'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec'
end
