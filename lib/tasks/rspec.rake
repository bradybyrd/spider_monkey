require 'ci/reporter/rake/rspec'
require 'rspec/core/rake_task'
include RSpec

namespace :rspec do
  RSpec::Core::RakeTask.new(:all => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:models => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/models/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:controllers => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/controllers/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:api => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/requests/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:activity => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/models/activity_spec.rb'
  end

  RSpec::Core::RakeTask.new(:features => ["ci:setup:rspec"]) do |t|
    t.pattern = 'spec/features/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:exclude_api_and_features => ["ci:setup:rspec"]) do |t|
    others_pattern = FileList['spec/*/'] - ['spec/requests/', 'spec/features/']
    others_pattern = others_pattern.collect{|dir_path| "#{dir_path}**/*_spec.rb" }
    t.pattern = others_pattern
  end
end

task "ci" => ["db:migrate"]
