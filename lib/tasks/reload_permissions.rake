namespace :app do
  task reload_permissions: :environment do
    begin
      puts 'Persisting permissions...'
      MigrationPermissionPersister.new.persist
      puts 'Done.'
    rescue => e
      puts "Failed. #{e.backtrace}"
    end
  end
end
