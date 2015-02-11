class RemoveLifecycleTemplateFromLifecycleMember < ActiveRecord::Migration
  def self.up
    remove_index :lifecycle_members, :column => :lifecycle_template_id
    remove_column  :lifecycle_members, :lifecycle_template_id
  end

  def self.down
    add_column  :lifecycle_members, :lifecycle_template_id, :integer, :null => false
    add_index "lifecycle_members", ["lifecycle_template_id"], :name => "i_lm_lti"
  end
end
