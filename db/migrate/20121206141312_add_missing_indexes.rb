class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :recent_activities, [:actor_id, :actor_type]
    add_index :recent_activities, [:object_id, :object_type]
    add_index :recent_activities, [:indirect_object_id, :indirect_object_type], :name => 'recent_act_indobjid_indobjtype'
    add_index :activity_attribute_values, [:value_object_id, :value_object_type], :name => 'actattrval_valobjid_valobjtype'
    add_index :email_recipients, [:recipient_id, :recipient_type]
    add_index :resource_allocations, [:allocated_id, :allocated_type]
  end

  def self.down
    remove_index :recent_activities, :column => [:actor_id, :actor_type]
    remove_index :recent_activities, :column => [:object_id, :object_type]
    remove_index :recent_activities, :column => [:indirect_object_id, :indirect_object_type], :name => 'recent_act_indobjid_indobjtype'
    remove_index :activity_attribute_values, :column => [:value_object_id, :value_object_type], :name => 'actattrval_valobjid_valobjtype'
    remove_index :email_recipients, :column => [:recipient_id, :recipient_type]
    remove_index :resource_allocations, :column => [:allocated_id, :allocated_type]
  end
end
