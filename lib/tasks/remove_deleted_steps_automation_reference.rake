desc "Remove automation references from deleted steps"

namespace :app do
  task :remove_deleted_steps_automation_reference => :environment do
    puts "Delete references"
    result = Step.used_in_deleted_requests.where('manual = ? AND script_id <> 0', false).update_all("script_id = 0")
    puts "References are deleted successfully from #{result} step(s)"
  end
end