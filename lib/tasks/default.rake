Rake::Task[:default].clear_prerequisites

desc "Silence $stdout"
task :shh do
  $stdout = File.open('/dev/null', 'w')
end

desc "Unsilence $stdout"
task :speakup do
  $stdout = STDOUT
end

if ENV["RUN_CODE_RUN"]
  desc "Run tests and coverage"
  task :default => ['shh', 'db:migrate:reset', 'speakup', 'cruise']
else
  desc "Run tests and coverage"
  task :default => ['cruise']
end
