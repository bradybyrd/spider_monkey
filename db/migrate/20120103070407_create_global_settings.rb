class CreateGlobalSettings < ActiveRecord::Migration
  def self.up
    create_table :global_settings do |t|
      t.string :default_logo
      t.string :company_name
      t.integer :base_request_number
      t.boolean :bladelogic_enabled
      t.string :bladelogic_ip_address
      t.string :bladelogic_username
      t.string :bladelogic_password
      t.string :bladelogic_rolename
      t.string :bladelogic_profile
      t.boolean :capistrano_enabled
      t.boolean :hudson_enabled
      t.string :session_key
      t.string :timezone
      t.boolean :one_click_completion
      t.integer :authentication_mode
      t.boolean :multi_app_requests
      t.string :default_date_format
      t.boolean :forgot_password
      t.string :ldap_host
      t.string :ldap_port
      t.string :ldap_component
      t.string :cas_server
      t.string :base_url
      t.string :calendar_preferences
      
      t.timestamps
    end
    Rake::Task['app:migrate_system_settings'].invoke
  end

  def self.down
    drop_table :global_settings
  end
end
