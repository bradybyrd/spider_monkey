class UpdatePermissionsList < ActiveRecord::Migration
  def up
    rename_column :permissions, :subject_class, :subject
    remove_column :permissions, :parent_id
    remove_column :permissions, :folder
    remove_column :permissions, :position
    remove_column :permissions, :depends_on_id
    remove_column :permissions, :subject_name

    MigrationPermissionPersister.new.persist
  end

  def down
    Permission.destroy_all

    rename_column :permissions, :subject, :subject_class
    add_column :permissions, :parent_id, :integer
    add_column :permissions, :folder, :boolean
    add_column :permissions, :position, :integer
    add_column :permissions, :depends_on_id, :integer
    add_column :permissions, :subject_name, :string
  end
end
