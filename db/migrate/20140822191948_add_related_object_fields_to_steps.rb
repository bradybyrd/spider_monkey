class AddRelatedObjectFieldsToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :create_new_package_instance, :boolean
    add_column :steps, :latest_package_instance, :boolean
    add_column :steps, :related_object_type, :string, default: "component"
  end
end
