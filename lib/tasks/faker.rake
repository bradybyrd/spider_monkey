namespace :app do
  task  :faker =>  :environment do
    require 'faker'
    I18n.reload!
    Rake::Task["app:setup:smartrelease"].invoke
    Rake::Task["fake:users"].invoke
    Rake::Task["fake:apps"].invoke
    Rake::Task["fake:teams"].invoke
    Rake::Task["fake:environments"].invoke
    Rake::Task["fake:servers"].invoke
    Rake::Task["fake:server_levels"].invoke
    Rake::Task["fake:server_groups"].invoke
    Rake::Task["fake:components"].invoke
    Rake::Task["fake:application_components"].invoke
    Rake::Task["fake:properties"].invoke
    Rake::Task["fake:component_properties"].invoke
    Rake::Task["fake:server_level_properties"].invoke
    Rake::Task["fake:application_environments"].invoke
    Rake::Task["fake:installed_components"].invoke
    Rake::Task["fake:categories"].invoke
    Rake::Task["fake:phases"].invoke
    Rake::Task["fake:assigned_apps"].invoke
    Rake::Task["fake:runtime_phases"].invoke
    Rake::Task["fake:releases"].invoke
    Rake::Task["fake:business_processes"].invoke
    Rake::Task["fake:package_contents"].invoke
    Rake::Task["fake:tasks"].invoke
    Rake::Task["fake:plan_templates"].invoke
    Rake::Task["fake:plan_stages"].invoke
    Rake::Task["fake:plans"].invoke
    Rake::Task["fake:plan_teams"].invoke
    Rake::Task["fake:groups"].invoke
    Rake::Task["fake:team_groups"].invoke
    Rake::Task["fake:users_groups"].invoke
    Rake::Task["fake:teams_users"].invoke
    Rake::Task["fake:requests"].invoke
    Rake::Task["fake:steps"].invoke
    Rake::Task["fake:procedures"].invoke

  end
end


