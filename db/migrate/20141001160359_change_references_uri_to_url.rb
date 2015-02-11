class ChangeReferencesUriToUrl < ActiveRecord::Migration
  def change
    rename_column :references, :url, :uri
    rename_column :instance_references, :url, :uri
  end
end
