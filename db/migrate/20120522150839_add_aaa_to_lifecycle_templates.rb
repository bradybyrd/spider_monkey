class AddAaaToLifecycleTemplates < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_templates, :archive_number, :string
    add_column :lifecycle_templates, :archived_at, :datetime
    add_index :lifecycle_templates, :archive_number
    add_index :lifecycle_templates, :archived_at
  end

  def self.down    
    remove_index :lifecycle_templates, :archive_number
    remove_index :lifecycle_templates, :archived_at
    remove_column :lifecycle_templates, :archived_at
    remove_column :lifecycle_templates, :archive_number
  end
end
