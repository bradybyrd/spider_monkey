class RenameIndexesForAssets < ActiveRecord::Migration
  def up
    rename_index "uploads", "index_assets_on_attachment", "index_uploads_on_attachment"
    rename_index "uploads", "index_assets_on_owner_id","index_uploads_on_owner_id"
    rename_index "uploads", "index_assets_on_owner_type","index_uploads_on_owner_type"
    rename_index "uploads", "index_assets_on_user_id","index_uploads_on_user_id"
  end

  def down
    rename_index "uploads", "index_uploads_on_attachment", "index_assets_on_attachment"
    rename_index "uploads", "index_uploads_on_owner_id","index_assets_on_owner_id"
    rename_index "uploads", "index_uploads_on_owner_type","index_assets_on_owner_type"
    rename_index "uploads", "index_uploads_on_user_id","index_assets_on_user_id"
  end
end
