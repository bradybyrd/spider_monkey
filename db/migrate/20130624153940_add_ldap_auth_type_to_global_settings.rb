class AddLdapAuthTypeToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :ldap_auth_type, :integer, :null => false, :default => 0
  end
end