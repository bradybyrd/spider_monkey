class AddLdapNameAttributesToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :ldap_first_name_attribute, :string
    add_column :global_settings, :ldap_last_name_attribute, :string
    add_column :global_settings, :ldap_mail_attribute, :string
  end
end