class CreateDefaultRoutes < ActiveRecord::Migration
  def self.up

    puts 'Initializing default routes for all existing applications...'

    begin

      # grab all of the existing applications
      apps = App.all

      # trigger the default route creation by accessing the default route accessor
      # which should find or create the route
      apps.map { |app| print '.' if app.default_route.present? }

    rescue => e
      puts "There was an error creating default routes: #{ e.message }"
      puts e.backtrace.join("\n")
    else
      puts "\nDefault routes created or verified for #{ apps.length } apps."
    end

  end

  def self.down
    puts 'Removing default routes is not supported through this migration because \
of possible dependencies in plans and related records. \
All routes will be removed if earlier migrations supporting those tables \
are rolled back.'
  end

end
