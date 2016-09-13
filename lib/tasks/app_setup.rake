require 'yaml'
require 'csv_importer'

db_config = YAML::load(File.open("#{Rails.root}/config/database.yml"))[Rails.env]
adapter = db_config['adapter']

namespace :app do

  namespace :load_csv do
    Dir[Rails.root + 'data/csv/*.csv'].each do |csv|
      template = File.basename(csv, '_template.csv')
      desc "Load the #{template} CSV"
      task template => :environment do
        puts "-------------- Loading #{template}_template.csv --------------"
        CSVImporter.import("#{template}_template")
      end
    end
  end

  namespace :setup do
    desc 'Sets up the application for smart|release'

    namespace :db do
      task :create_and_migrate do
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
        Rake::Task['db:migrate'].invoke
      end
      task :create_and_migrate_no_drop do
        # for oracle check if database exist, othervise error will be raise instead of asking input system pasword
        # fix related to update of 'activerecord-jdbc-adapter' to version 1.3.7: ask to insert system password to create db
        if adapter =~ /oracle/
          ActiveRecord::Base.establish_connection(db_config)
          ActiveRecord::Base.connection
        else
          Rake::Task['db:create'].invoke
        end
        Rake::Task['db:migrate'].invoke
      end
    end

    desc 'Actually sets up the application for BMC Release Process Management'
    task :do_smartrelease do
      print "Enabling Forgot Password...\n"
      GlobalSettings[:forgot_password] = true
      print "Setting Default Calendar Preferences...\n"
      Rake::Task['sr:set_default_calendar_preferences'].invoke
      print " Done.\n"

      admin = User.find_by_login('admin')

      unless admin
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts 'Default Admin user account is not created successfully'
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      end

      print 'Removing Not Visible role... '
      DefaultRoles::NotVisibleRole.destroy

      if PostgreSQLAdapter
        puts 'Resetting primary key sequences...'

        tables = [Route.table_name, RouteGate.table_name]
        tables.each { |table_name| ActiveRecord::Base.connection.reset_pk_sequence!(table_name) }
      end

      puts 'Done.'
    end

    desc 'Sets up the application for BMC Release Process Management'
    task :smartrelease => ['db:create_and_migrate', 'app:fixtures:clean_install', 'load_csv:request_project', 'do_smartrelease'] do
    end

    desc 'Sets up the application for BMC Release Process Management on empty db'
    task :smartrelease_no_drop => ['db:create_and_migrate_no_drop', 'app:fixtures:clean_install', 'load_csv:request_project', 'do_smartrelease'] do
    end

  end

end
