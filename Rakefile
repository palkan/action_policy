# frozen_string_literal: true

require "rake/testtask"
require "rspec/core/rake_task"

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
end

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :test do
  task :isolated do
    Dir.glob("test/**/*_test.rb").all? do |file|
      sh(Gem.ruby, "-w", "-Ilib:test", file)
    end || raise("Failures")
  end

  task ci: %w[test:isolated spec]
end

task default: [:rubocop, :test, :spec]
