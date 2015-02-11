
desc 'Migrate settings from settings_hash to GlobalSettings'
namespace :app do
  task :migrate_system_settings do
    rows = ActiveRecord::Base.connection.select_rows('select * from system_settings')
    #rows = GlobalSettings.find_by_sql("select * from system_settings")

    settings_hash = HashWithIndifferentAccess.new #=> {}
    if rows
      rows.each do |row|
        settings_hash[row[1]] = row[2]
      end
    end

    GlobalSettings[:timezone] = settings_hash[:time_zone]
    if settings_hash[:one_click_completion] && settings_hash[:one_click_completion].to_i == 1
      GlobalSettings[:one_click_completion] = true
    end
    if settings_hash[:capistrano_enabled] && settings_hash[:capistrano_enabled].to_i == 1
      GlobalSettings[:capistrano_enabled] = true
    end
    if settings_hash[:bladelogic_enabled] && settings_hash[:bladelogic_enabled].to_i == 1
      GlobalSettings[:bladelogic_enabled] = true
    end
    if settings_hash[:hudson_enabled] && settings_hash[:hudson_enabled].to_i == 1
      GlobalSettings[:hudson_enabled] = true
    end
    GlobalSettings[:session_key] = settings_hash[:session_key]
    if settings_hash[:company_name]
      GlobalSettings[:company_name] = settings_hash[:company_name]
    end
    GlobalSettings[:base_url] = settings_hash[:base_url]
    if settings_hash[:default_date_format]
      GlobalSettings[:default_date_format] = settings_hash[:default_date_format]
    end
    if settings_hash[:base_request_number]
      GlobalSettings[:base_request_number] = settings_hash[:base_request_number].to_i
    end
    if settings_hash[:calendar_preferences]
      GlobalSettings[:calendar_preferences] = settings_hash[:calendar_preferences]
    end
    if settings_hash[:default_logo]
      GlobalSettings[:default_logo] = settings_hash[:default_logo]
    end
    if settings_hash[:bladelogic_ip_address]
      GlobalSettings[:bladelogic_ip_address] = settings_hash[:bladelogic_ip_address]
    end
    if settings_hash[:bladelogic_username]
      GlobalSettings[:bladelogic_username] = settings_hash[:bladelogic_username]
    end
    if settings_hash[:bladelogic_password]
      GlobalSettings[:bladelogic_password] = settings_hash[:bladelogic_password]
    end
    if settings_hash[:bladelogic_rolename]
      GlobalSettings[:bladelogic_rolename] = settings_hash[:bladelogic_rolename]
    end
    if settings_hash[:bladelogic_profile]
      GlobalSettings[:bladelogic_profile] = settings_hash[:bladelogic_profile]
    end
    if settings_hash[:ldap_authentication] && settings_hash[:ldap_authentication].to_i == 1
      GlobalSettings.update_attributes!(authentication_mode: 1,
                                        ldap_host: settings_hash[:ldap_host],
                                        ldap_port: settings_hash[:ldap_port],
                                        ldap_component: settings_hash[:ldap_component])
    elsif settings_hash[:cas_authentication] && settings_hash[:cas_authentication].to_i == 1
      GlobalSettings.update_attributes!(authentication_mode: 2,
                                        cas_server: settings_hash[:cas_server])
    else
      GlobalSettings[:authentication_mode] = 0
      if settings_hash[:forgot_password] && settings_hash[:forgot_password].to_i == 1
        GlobalSettings[:forgot_password] = true
      end
    end

    puts "\nMigration to GlobalSettings completed successfully"
  end
end
