class AddCodeSynchRequiredToChangeRequest2501 < ActiveRecord::Migration
  def self.up
  	add_column :change_requests, :u_code_synch_required, :string  	
  end

  def self.down
  	remove_column :change_requests, :u_code_synch_required
  end
end
