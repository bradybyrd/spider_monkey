class UpdateTargetHolderTypeValueLinkedItems < ActiveRecord::Migration
  def up
  	LinkedItem.update_all "source_holder_type = 'Plan'", "source_holder_type = 'Lifecycle'"
  	LinkedItem.update_all "target_holder_type = 'Plan'", "target_holder_type = 'Lifecycle'"
  end

  def down
  	LinkedItem.update_all "source_holder_type = 'Lifecycle'", "source_holder_type = 'Plan'"
  	LinkedItem.update_all "target_holder_type = 'Lifecycle'", "target_holder_type = 'Plan'"  	
  end
end
