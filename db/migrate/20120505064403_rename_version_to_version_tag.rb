class RenameVersionToVersionTag < ActiveRecord::Migration
  def self.up
    rename_table  :versions, :version_tags
    rename_column :steps, :version_id, :version_tag_id
    rename_column :application_environments, :version_id, :version_tag_id
  end

  def self.down
    rename_table  :version_tags, :versions
    rename_column :steps, :version_tag_id, :version_id
    rename_column :application_environments, :version_tag_id, :version_id
  end
end
