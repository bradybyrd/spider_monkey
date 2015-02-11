class AddLdapBindPasswordToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :ldap_bind_user, :string
    add_column :global_settings, :ldap_bind_password, :string
  end
end