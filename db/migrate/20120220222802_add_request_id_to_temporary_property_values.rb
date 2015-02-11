class AddRequestIdToTemporaryPropertyValues < ActiveRecord::Migration
  def self.up
    add_column :temporary_property_values, :request_id, :integer
    add_column :temporary_property_values, :deleted_at, :datetime
    add_index :temporary_property_values, :request_id, :name => "temp_props_by_request"
    
    TemporaryPropertyValue.all.each do |prop|
      if prop.step.request_id.nil?
        prop.request_id = prop.step.parent.request_id
      else
        prop.request_id = prop.step.request_id
      end
      prop.save(false)
    end
  end

  def self.down
    remove_column :temporary_property_values, :deleted_at
    remove_column :temporary_property_values, :request_id
  end
end
