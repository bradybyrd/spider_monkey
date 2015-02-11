# rake homeaway:set_global_access
desc "Sets `global_access` attribute to TRUE for all users so every app and environment is made visible to all users regardless of permissions set"

def ask(message)
  puts "#{message}:"
  val = STDIN.gets.chomp
  if val.nil? || val.strip.empty?
    return ask(message)
  else
    return val
  end
end

namespace :homeaway do
  task :set_global_access => :environment do
    
    message = "***************************************\n"
    message += "This task will set global  access to attribute to TRUE for all the users of the system.\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    confirmation = ask(message)
    if "y".casecmp(confirmation) == 0
      puts "Setting global access in application for all users"
      User.all.each do |user|
        puts user.name_for_index
        user.update_attribute(:global_access, true)
      end
      puts "Task completed successfully."
    else
      puts "Task aborted without making any changes in system database"
    end
  end
end