EXCLUDE_FROM_STEP = [:frozen_owner, :frozen_component, :frozen_automation_script, :frozen_bladelogic_script, :frozen_task]

namespace :sr do
  task :unfreeze_template_steps => :environment do
    templates = RequestTemplate.all
    templates.each do |temp|
      puts "Fixing Steps for #{temp.name}"
      unless temp.request.nil?
        temp.request.steps.each do |cur|
          updater = {}
          EXCLUDE_FROM_STEP.each do |fld|
            updater[fld] = nil
          end
          cur.update_attributes(updater)
        end  
      end
    end
    puts "Rake complete !!!"
  end
end