desc "Clears direct access permissions of apps and provide co-ordinator access to all members of team for all the apps of team"

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
  task :clear_direct_access => :environment do
    
    message = "***************************************\n"
    message += "This task will clear direct access to apps of all the users.\n"
    message += "Press Y to continue or any other key to exit\n"
    message += "***************************************"
    confirmation = ask(message)

    if "y".casecmp(confirmation) == 0
      UserApp.destroy_all
      puts "Direct access to apps of all users deleted."
    else
      puts "Task aborted without making any changes in system database"
    end
  end
end