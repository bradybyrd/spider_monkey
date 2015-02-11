desc "Installs all applications in all environments and installs in all environments"

# Constants
Import_Tables = {
  "apps" => ["id", "name", ""],
  "environments" => ["id", "name", ""],
  "servers" => ["id", "name", ""],
  "environment_servers" => ["id", "name", ""],
  "installed_components_servers" => ["id", "name", ""],
  "application_environments" => ["id", "name", ""],
  "application_components" => ["id", "name", ""]
  }

def ask(message)
  puts "#{message}:"
  val = STDIN.gets.chomp
  if val.nil? || val.strip.empty?
    return ask(message)
  else
    return val
  end
end

def print_and_exit message, errcode = 1
  print "#{message}\n"
  $stdout.flush
  exit errcode
end


namespace :import do
  task :installed_components => :environment do
    
    message = "***************************************\n"
    message += "This task will import components into environments.\n"
    message += "and install all components for each app into the environments\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    confirmation = ask(message)
    # global_access_confirmation = ask("Do you want to set Global Access for all users part of any team. Press Y for yes.")
    global_access_confirmation = false
    if "y".casecmp(confirmation) == 0
      cnt = 0
      puts "Assigning Applications to Environments..."
      cur_app_ids = App.all.map( &:id)
      Environment.all.each do |env|
        cur_app_ids.each do |app_id|
          cnt += 1
          ApplicationEnvironment.find_or_create_by_app_id_and_environment_id(app_id, env.id)
        end
      end
      puts "Created #{cnt.to_s} application-environment associations"
      
      cnt = 0
      puts "Installing ApplicationComponents in Environments..."
      App.all.each do |app|
        app.application_components.each do |ac|
          app.application_environments.each do |app_env|
            cnt += 1
            InstalledComponent.create!(:application_component => ac, :application_environment => app_env)
          end
        end
      end
      puts "Created #{cnt.to_s} installed components"
      
    else
      puts "Task aborted without making any changes in system database"
    end
  end
  
  task :install_servers => :environment do
    message = "***************************************\n"
    message += "This task read a csv file of servers and components.\n"
    message += "and installs each server onto the component\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    #confirmation = ask(message)
    #global_access_confirmation = false
    if true #"y".casecmp(confirmation) == 0
      print_and_exit "Usage: rake import:install_servers <csv_file>" if ARGV[1].nil?

      filename = ARGV[1]
      filename = "#{filename}.csv" unless filename =~ /\.\w+$/
      #filename = File.join("data", "csv", filename) unless File.exist? filename
      begin
        csv = File.open(filename)
      rescue Errno::ENOENT => e
        print_and_exit e
      end
      require 'csv'
      lines = CSV.parse(csv)
      #First Line is table_name
      table_name = lines.first[1].downcase
      print_and_exit "Not a valid table for import: #{table_name}" unless Import_Tables.has_key?(table_name)  
      puts "Importing #{filename} into table #{table_name}"
      icnt = 0
      column_names = lines[1][0..15]
      app_pos = column_names.index("app_id")
      env_pos = column_names.index("environment_id")
      comp_pos = column_names.index("component_id")
      server_pos = column_names.index("server_id")
      unless (app_pos.nil? or env_pos.nil? or comp_pos.nil? or server_pos.nil?)
        content = lines[2..-1]
        content.reject { |c| c[app_pos] == "0" }.each_with_index do |row, idx|
           icnt += 1
           app_id = row[app_pos]
           env_id = row[env_pos]
           comp_id = row[comp_pos]
           server_id = row[server_pos]
           serv = Server.find(server_id.to_i)
           unless serv.nil?
             app_comp = ApplicationComponent.find_by_app_id_and_component_id(app_id, comp_id)
             app_env = ApplicationEnvironment.find_by_app_id_and_environment_id(app_id, env_id)
             ic = InstalledComponent.find_by_application_component_id_and_application_environment_id(app_comp.id,app_env.id)
             ic.servers << serv
             puts "Adding to #{serv.name} to installed servers (#{icnt.to_s})"
           end
        end
        puts "Created #{icnt.to_s} installed servers"
      else
        puts "Missing key fields need: server_id, app_id, environment_id and component_id"
      end
    else
      puts "Task aborted without making any changes in system database"
    end
  end
  
  task :install_component_servers => :environment do
    message = "***************************************\n"
    message += "This task read a csv file of apps, servers, envs and components.\n"
    message += "and installs each server onto the component\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    #confirmation = ask(message)
    #global_access_confirmation = false
    if true #"y".casecmp(confirmation) == 0
      print_and_exit "Usage: rake import:install_component_servers <csv_file>" if ARGV[1].nil?

      filename = ARGV[1]
      filename = "#{filename}.csv" unless filename =~ /\.\w+$/
      #filename = File.join("data", "csv", filename) unless File.exist? filename
      begin
        csv = File.open(filename)
      rescue Errno::ENOENT => e
        print_and_exit e
      end
      require 'csv'
      lines = CSV.parse(csv)
      #First Line is table_name
      table_name = lines.first[1].downcase
      print_and_exit "Not a valid table for import: #{table_name}" unless Import_Tables.has_key?(table_name)  
      puts "Importing #{filename} into table #{table_name}"
      icnt = 0
      column_names = lines[1][0..15]
      app_pos = column_names.index("app_id")
      env_pos = column_names.index("environment_id")
      comp_pos = column_names.index("component_id")
      server_pos = column_names.index("server_id")
      unless (app_pos.nil? or env_pos.nil? or comp_pos.nil? or server_pos.nil?)
        content = lines[2..-1]
        content.reject { |c| c[app_pos] == "0" }.each_with_index do |row, idx|
           icnt += 1
           app_id = row[app_pos]
           env_id = row[env_pos]
           comp_id = row[comp_pos]
           server_id = row[server_pos]
           puts "Data: App: #{app_id.to_s}, Env: #{env_id.to_s}, Comp: #{comp_id.to_s}, Srv: #{server_id.to_s}"
           serv = Server.find(server_id.to_i)
           unless (serv.nil? || comp_id == 0 || app_id == 0)
             app_comp = ApplicationComponent.find_or_create_by_app_id_and_component_id(app_id, comp_id)
             app_env = ApplicationEnvironment.find_or_create_by_app_id_and_environment_id(app_id, env_id)
             puts "Installing #{app_comp.app.name} - #{app_comp.component.name} in #{app_env.environment.name}"
             ic = InstalledComponent.find_or_create_by_application_component_id_and_application_environment_id(app_comp.id,app_env.id)
             ic.servers << serv
             puts "Adding to #{serv.name} to installed servers (#{icnt.to_s})"
           end
        end
        puts "Created #{icnt.to_s} installed servers"
      else
        puts "Missing key fields need: server_id, app_id, environment_id and component_id"
      end
    else
      puts "Task aborted without making any changes in system database"
    end
  end

  task :install_all_components => :environment do
    message = "***************************************\n"
    message += "This task read a csv file of servers and components.\n"
    message += "and installs each server onto the component\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    #confirmation = ask(message)
    #global_access_confirmation = false
    if true #"y".casecmp(confirmation) == 0
      print_and_exit "Usage: rake import:install_servers <csv_file>" if ARGV[1].nil?

      filename = ARGV[1]
      filename = "#{filename}.csv" unless filename =~ /\.\w+$/
      #filename = File.join("data", "csv", filename) unless File.exist? filename
      begin
        csv = File.open(filename)
      rescue Errno::ENOENT => e
        print_and_exit e
      end
      require 'csv'
      lines = CSV.parse(csv)
      #First Line is table_name
      table_name = lines.first[1].downcase
      print_and_exit "Not a valid table for import: #{table_name}" unless Import_Tables.has_key?(table_name)  
      puts "Importing #{filename} into table #{table_name}"
      icnt = 0
      column_names = lines[1][0..15]
      app_pos = column_names.index("app_id")
      env_pos = column_names.index("environment_id")
      comp_pos = column_names.index("component_id")
      server_pos = column_names.index("server_id")
      unless (app_pos.nil? or env_pos.nil? or comp_pos.nil? or server_pos.nil?)
        content = lines[2..-1]
        content.reject { |c| c[app_pos] == "0" }.each_with_index do |row, idx|
           icnt += 1
           app_id = row[app_pos]
           env_id = row[env_pos]
           comp_id = row[comp_pos]
           server_id = row[server_pos]
           serv = Server.find(server_id.to_i)
           unless serv.nil?
             app_comp = ApplicationComponent.find_by_app_id_and_component_id(app_id, comp_id)
             app_env = ApplicationEnvironment.find_by_app_id_and_environment_id(app_id, env_id)
             ic = InstalledComponent.find_by_application_component_id_and_application_environment_id(app_comp,app_env)
             ic.servers << serv
             puts "Adding to #{serv.name} to installed servers (#{icnt.to_s})"
           end
        end
        puts "Created #{icnt.to_s} installed servers"
      else
        puts "Missing key fields need: server_id, app_id, environment_id and component_id"
      end
    else
      puts "Task aborted without making any changes in system database"
    end
  end  
end