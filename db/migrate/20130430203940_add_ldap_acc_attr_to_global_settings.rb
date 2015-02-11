class AddLdapAccAttrToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :ldap_account_attribute, :string
  end
end