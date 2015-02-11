namespace :user do
  namespace :assigned_apps do
    desc 'Update roles for missing assigned application assigned environments.'
    task update_roles: :environment do
      Kernel.puts "Assigned environment is depricated, and will be removed in BRPM 4.6"
      User.all.each do |user|
        user.assigned_apps.each do |assigned_app|
          app_environment_ids = assigned_app.app.application_environments.pluck(:environment_id)
          assigned_environment_ids = assigned_app.assigned_environments.pluck(:environment_id)
          missing_environments = app_environment_ids - assigned_environment_ids

          missing_environments.each do |env_id|
            assigned_app.assigned_environments.find_or_create_by_environment_id(env_id) do |assigned_environment|
              assigned_environment.role = user.roles.first
            end
          end

          if missing_environments.present?
            puts '____________________________________________________________________________________'
            puts "AssignedApp -> id: #{assigned_app.id}"
            puts "App -> id: #{assigned_app.app.id}, name: #{assigned_app.app.name}"
            puts "User -> id: #{user.id}, login: #{user.login}"
            puts "Missing Environment IDs -> #{missing_environments.inspect}"
            puts "Role assigned -> #{user.roles.first}"
            puts '------------------------------------------------------------------------------------'
            puts ''
          end
        end
      end
    end
  end
end
