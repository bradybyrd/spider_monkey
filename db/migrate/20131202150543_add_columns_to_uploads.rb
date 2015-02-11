class AddColumnsToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :deleted, :boolean, default: false, null: false
    add_column :uploads, :description, :string

    add_index :uploads, :deleted, name: 'I_UPLOADS_DELETED'
  end
end
