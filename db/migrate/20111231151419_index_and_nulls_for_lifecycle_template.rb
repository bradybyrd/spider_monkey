class IndexAndNullsForLifecycleTemplate < ActiveRecord::Migration
  def self.up
    change_column :lifecycle_templates, :name, :string, :null => false
    change_column :lifecycle_templates, :template_type, :string, :null => false
    add_index :lifecycle_templates, :template_type, :name => "i_lc_temp_tt"
    add_index :lifecycle_templates, :is_automatic, :name => "i_lc_temp_is_auto"
    add_index :lifecycle_templates, :name, :unique => true, :name => "i_lc_temp_name"
  end

  def self.down
    change_column :lifecycle_templates, :name, :string, :null => true
    change_column :lifecycle_templates, :template_type, :string, :null => true
    remove_index :lifecycle_templates, :template_type, :name => "i_lc_temp_tt"
    remove_index :lifecycle_templates, :is_automatic, :name => "i_lc_temp_is_auto"
    remove_index :lifecycle_templates, :name, :name => "i_lc_temp_name"
  end
end
