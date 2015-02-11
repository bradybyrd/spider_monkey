desc "Set default Calendar preferences"

namespace :sr do
  task :set_default_calendar_preferences => :environment do
    
    calendar_preferences = ["aasm.current_state", 
                            "project_name", 
                            "business_process_name", 
                            "app_name", 
                            "environment_name", 
                            "package_content_tags", 
                            "owner_name", 
                            "release_name", 
                            "rescheduled", 
                            "id", 
                            "name"]
    GlobalSettings[:calendar_preferences] = calendar_preferences
    puts "  Default Calendar preferences successfully added."
  end
end