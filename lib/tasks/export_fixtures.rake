desc "Export data from tables in the current environment db to fixtures (YML format). "
namespace :db do
  namespace :fixtures do
    task :export => :environment do

      # Set conn with database
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

#     Renaming Tables whose names were shortened to work with Oracle
      join_tables = {
          'installed_components_server_aspect_groups' => 'icsags',
          'installed_components_server_aspects' => 'icsas',
          'script_argument_to_property_maps' => 'satpms',
          'server_aspect_groups_server_aspects' => 'sagsas'
      }
      # Fixtures will be stored in RAILS_ROOT/data/fixtures
      file_base_path = "#{RAILS_ROOT}/data/oracle/#{ENV['TO']}"
      File.makedirs(file_base_path) unless File.file?(file_base_path)
      puts "\nExporting to: #{file_base_path}"
      puts "RAILS_ENV is #{RAILS_ENV}"

      Dir.chdir(file_base_path)
      log_file = File.new("export_fixtures.log", "w+")

      # Table names can be passed as rake db:fixtures:export TABLE=users,activities or nothing
      table_names = ENV["TABLE"].nil? ? ActiveRecord::Base.connection.tables : ENV["TABLE"].to_s.split(",")

      unwanted_tables = ['schema_info',
       'standard_operating_procedures',
       'activity_phase_times'
      ]  # Add unwanted table names in this array so they will be skipped
      views = ['activities_view', 'containers_view', 'financials_view'] # These are virtual tables

      (table_names - unwanted_tables - views).each do |table_name|
        puts "\nExporting #{table_name}..."
        yml_file = "#{file_base_path}/#{table_name}.yml"
        i = "000000"
        File.delete(yml_file) if File.exist?(yml_file)
        File.open(yml_file, 'w' ) do |file_object|
          begin
            sql = "SELECT * FROM #{table_name}"
            data = ActiveRecord::Base.connection.select_all(sql)
            puts " Rows: #{data.size}"
            log_file.write("#{table_name}: #{data.size}")
            log_file.write("\n")
            file_object.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
            }.to_yaml
            puts " Status: Completed"
          rescue Exception => e
            puts " Status: Aborted"
            puts " Reason: #{e.message}"
          end
        end
      end
      puts "Export fixtures task completed.\n"
      log_file.close
      puts '*************** List of table names and total records ********************'
      puts File.open("export_fixtures.log").read
      Dir.chdir(RAILS_ROOT)
      Rake::Task["db:fixtures:store_manipulated_data"].invoke
    end

    task :store_manipulated_data => :environment do
      serialized_columns = {
        'User' => 'roles',
        'User' => 'calendar_preferences',
        'Activity' => 'blockers',
        'Activity' => 'theme',
        'ActivityAttribute' => 'attribute_values'
      }
      file_base_path = "#{RAILS_ROOT}/data/oracle/#{ENV['TO']}"
      Dir.chdir(file_base_path)
      sa = File.new("serialized_attributes_data.txt", "w+")
      serialized_columns.each_pair { |klass, attr|
        klass.constantize.all.each do |r|
          puts "#{klass} - #{attr} - #{r.id} - #{r.send(attr).join(',')}"
          sa.write("#{klass} - #{attr} - #{r.id} - #{r.send(attr).join(',')}" )
          sa.write("\n")
        end
      }

      Activity.all.each do |a|
        temp = []
        a.phase_start_dates.each_pair { |key, value|
          temp << "#{key} => #{value}"
        }
        sa.write("Activity - phase_start_dates - #{a.id} - #{temp.join(',')}")
        sa.write("\n")
      end

      sa.close
      Dir.chdir(RAILS_ROOT)
    end

  end
end

