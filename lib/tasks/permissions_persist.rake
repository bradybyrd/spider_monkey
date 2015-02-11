namespace :permissions do
  desc "Persist permissions to the database"
  task :persist => :environment do
    PermissionPersister.new.persist
  end
end
