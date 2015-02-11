require 'fileutils'

namespace :db do
  namespace :fixtures do
    
    desc 'Create YAML test fixtures from data in an existing database.  Defaults to development database.  Set RAILS_ENV to override.'
    task :dump => :environment do
      if File.exists?("tmp/fixtures")
          puts "tmp/fixtures dir exists, clearing..."
          FileUtils.rm_f(Dir["tmp/fixtures/*"])
      else
          puts "tmp/fixtures dir doesn't exist so we're creating..."
          FileUtils.makedirs('tmp/fixtures')
      end
      # set up the database connection
      ActiveRecord::Base.establish_connection(RAILS_ENV)
      # cache the sql statement template
      sql  = "SELECT * FROM %s"      
      # get the list of tables
      all_tables = ActiveRecord::Base.connection.tables
      # reject views
      tables_to_dump = all_tables.reject { |table_name| table_name.include?("_view") }
      # remove tables to skip
      skip_tables = ["schema_migrations"]
      tables_to_dump = tables_to_dump - skip_tables
      
      # now loop through and generate yml from the raw table names, skipping model
      # references which in the previous version resulted in a lot of errors because
      # the custom table names in the model were not being followed
      tables_to_dump.each do |table_name|
        i = "000"
        File.open("#{RAILS_ROOT}/tmp/fixtures/#{table_name}.yml", 'w') do |file|
          # new direct sql method instead of constantizing and reversing since custom tables failed
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end
  end
end
