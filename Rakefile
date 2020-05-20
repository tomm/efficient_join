require "bundler/gem_tasks"
require "rake/extensiontask"

task :build => :compile

Rake::ExtensionTask.new("efficient_join") do |ext|
  ext.lib_dir = "lib/efficient_join"
end

task :default => [:clobber, :compile, :spec]
