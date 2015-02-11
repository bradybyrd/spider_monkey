class AddRequestMethodToReferences < ActiveRecord::Migration
  def change
    add_column :references, :resource_method, :string, default: 'File'
  end
end
