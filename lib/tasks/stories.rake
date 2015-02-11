namespace :app do
  desc "Run all Story Runner stories for this application"
  task :stories do
    ruby "stories/all.rb --colour"
  end
end