class AddLdapBindBaseToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :ldap_bind_base, :string
  end
end