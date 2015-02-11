desc "Updates the installed_component_id for all steps. "
namespace :app do
  task :set_installed_component => :environment do
      # Set conn with database
      #ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      num_to_do = Step.count(:all, :conditions => "component_id is not null and installed_component_id is null")
      own_id = User.find_by_login("admin").try(:id) || 2
      block_size = 1000
      id_low = 0
      id_high = 0
      record_count = 1
      loop_cnt = 1
      while record_count > 0
        id_low = id_high
        id_high = block_size * loop_cnt
        all_steps = Step.find(:all, :conditions => "component_id is not null and installed_component_id is null", :limit => block_size, :offset => id_low)
        puts "Setting installed component on steps (with components) [#{id_low.to_s}-#{id_high.to_s}] to do"
        record_count = all_steps.size
        break if record_count == 0
        inc = num_to_do > 1000 ? 10 : 1
        icnt = 0; tot_cnt = 0
        all_steps.each do |step|
          msg = ""
          tot_msg = "[#{tot_cnt} of #{num_to_do}]"
          if step.installed_component_id.nil?
            if step.request.nil?
              msg += "#{tot_msg} Step - #{step.id.to_s}, No Request attached!   "
            else
              attrs = {:installed_component_id => step.get_installed_component.try(:id)}
              if step.owner_id.nil?
                attrs[:owner_id] = step.request.requestor_id || own_id
                attrs[:owner_type] = "User"
                msg += ", fixing owner (was nil)"
              end
              step.update_attributes attrs
              msg += "#{tot_msg} Step - #{step.id.to_s}, CompID = #{step.component_id.to_s}, IC = #{step.installed_component_id.to_s}   "
            end
          else
            msg += "#{tot_msg} Step - #{step.id.to_s}, Installed component already set - IC = #{step.installed_component_id.to_s}"
          end
          tot_cnt += 1
          puts msg if icnt == inc
          icnt = (icnt == inc) ? 0 : (icnt + 1)
        end
        loop_cnt += 1
      end
      puts "\nUpdate completed successfully"
  end
end
