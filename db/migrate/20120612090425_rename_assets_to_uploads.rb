class RenameAssetsToUploads < ActiveRecord::Migration
  def change
    rename_table :assets, :uploads
  end
end
