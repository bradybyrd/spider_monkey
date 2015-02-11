require 'active_record/fixtures'
require 'rake'

desc "Populates default data reqd. for the app from the fixtures into the current environment's database."
namespace :db  do
  namespace :fixtures do
    task :import => :environment do

      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

      # Fixtures will be retrieved from RAILS_ROOT/data/fixtures/XXX

      file_base_path = "#{RAILS_ROOT}/data/oracle/#{ENV['FROM']}"

      Dir.chdir(file_base_path)
      log_file = File.new("import_fixtures.log", "w+")
      error_log = File.new("errors.log", "w+")
      # Set conn with database
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

      puts "\nExporting to: #{file_base_path}"
      puts "RAILS_ENV is #{RAILS_ENV}"

      # Table names can be passed as rake db:fixtures:import TABLE=users,activities or nothing
      files_array = ENV["TABLE"].nil? ? Dir.glob(File.join(file_base_path, '*.{yml}')) : ENV["TABLE"].to_s.split(",")

      files_array.each do |fixture_file|
       file_name = File.basename(fixture_file.strip, ".yml")
        puts "\n Importing " + file_name + "..."
        begin
          Fixtures.create_fixtures(file_base_path, File.basename(fixture_file.strip, '.yml'))
          records = ActiveRecord::Base.connection.select_all("SELECT * FROM #{file_name}")
          puts " Rows Added: #{records.size}"
          log_file.write("#{file_name}: #{records.size}")
          log_file.write("\n")
          puts " Status: Completed"
        rescue Exception => e
          error_log.write("\n\n")
          error_log.write("\n Importing " + file_name + "...")
          error_log.write("\n")
          error_log.write(e.message)
          puts e.message
        end
      end
      log_file.close
      error_log.close
      puts '*************** List of table names and total records ********************'
      puts File.open("import_fixtures.log").read
      puts "\nTask completed!"
      puts "\n Check and Compare import_fixtures.log and export_fixtures.log to verify that all the exported data was loaded to db"
      Dir.chdir(RAILS_ROOT)
      Rake::Task["db:fixtures:load_manipulated_data"].invoke
    end

    task :load_manipulated_data => :environment do

      class ActivityCustomAttribute < ActivityAttribute
        attr_accessor :values
      end
      class ActivityStaticAttribute < ActivityAttribute
        attr_accessor :values
      end
      class ActivityWidget < ActivityAttribute
        attr_accessor :values
      end

      file_base_path = "#{RAILS_ROOT}/data/oracle/#{ENV['FROM']}/serialized_attributes_data.txt"

      ActiveRecord::Base.connection.execute("UPDATE users SET roles = NULL")
      ActiveRecord::Base.connection.execute("UPDATE users SET calendar_preferences = NULL")
      ActiveRecord::Base.connection.execute("UPDATE activities SET theme = NULL")
      ActiveRecord::Base.connection.execute("UPDATE activities SET blockers = NULL")
      ActiveRecord::Base.connection.execute("UPDATE activities SET phase_start_dates = NULL")
      ActiveRecord::Base.connection.execute("UPDATE activity_attributes SET attribute_values = NULL")

      File.open(file_base_path, "r") do |file|
        counter = 1
        while (line = file.gets)
          data = line.split(' - ')
          if data[1] == 'phase_start_dates' # psd
            psd_hash = {}
            unless data[3] == "\n"
              data[3].split(',').flatten.each { |h|
                psd_attr = h.split('=>')
                psd_hash[psd_attr[0].gsub(/[\t\n\r\f]/, "").strip] = psd_attr[1].gsub(/[\t\n\r\f]/, "").strip if psd_attr[1]
              }
            end
            puts "#{data[2]}: #{psd_hash.inspect}"
            Activity.find(data[2]).update_attribute(:phase_start_dates, psd_hash)
          else
            record = data[0].constantize.find(data[2])
            record.update_attribute(data[1].to_sym, (data[3] == '\n' ? nil : data[3].split(',').collect {|e| e.gsub(/[\t\n\r\f]/, "") unless e.nil? }))
          end
          puts "#{counter}: #{line}"
          counter += 1
        end
      end
    end

  end
end

