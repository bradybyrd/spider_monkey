# September 9, 2010 
# Implement User Capabilities as per roles and access granted to applications and their environments 
# http://www.pivotaltracker.com/story/show/4877517

# rake sr:access_control:assigned_apps_data

# Modified again on Feb 17, 2011 after including `team_id` in `assigned_apps` table.

# TODO - Rewrite this rake as methods used in this rake are removed 
# that were related to user_apps and teams_roles as these tables are now removed
desc "Add data in tables `assigned_apps` & `assigned_environments` from `user_apps` & `team_roles`"
namespace :sr do
  namespace :access_control do
    task :assigned_apps_data => :environment do
      Kernel.puts "Assigned environment is depricated, and will be removed in BRPM 4.6"            
      AssignedApp.destroy_all
      
      User.all.each do |user|
        puts "Loading Data for User #{user.login}"
        # Loading data in assigned_apps for Directly Accessisble apps
        user.user_apps.visible.collect {|a|{ a.app_id => a.env_role_mapping}}.each do |app_env|
          app_env.keys.each do |app_id|
            assigned_app = user.assigned_apps.create(:app_id => app_id, :team_id => nil)
            app_env[app_id].each_pair { |environment_id, role|

              if assigned_app.save
                assigned_app.assigned_environments.create(:environment_id => environment_id, :role => role)            
              end

            }
          end
        end
        
        # Loading data in assigned_apps for Apps accessible via Team
        user.teams.each do |team|
          user.set_assigned_apps_data(team.id)
        end
        
      end
    end
  end
end