class UpdateDefaultValuesForProperties26 < ActiveRecord::Migration
  def up
  	change_column :properties, "default_value", :string, :limit => 4000
  	change_column :property_values, "value", :string, :limit => 4000
  end

  def down
  	change_column :properties, "default_value", :string
  	change_column :property_values, "value", :string
  end
end
