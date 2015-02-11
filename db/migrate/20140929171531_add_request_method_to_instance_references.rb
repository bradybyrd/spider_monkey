class AddRequestMethodToInstanceReferences < ActiveRecord::Migration
  def change
    add_column :instance_references, :resource_method, :string, default: 'File'
  end
end
