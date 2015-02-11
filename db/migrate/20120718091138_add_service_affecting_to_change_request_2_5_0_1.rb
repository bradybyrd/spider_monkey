class AddServiceAffectingToChangeRequest2501 < ActiveRecord::Migration
  def self.up
  	add_column :change_requests, :u_service_affecting, :boolean, :default => true
  end

  def self.down
  	remove_column :change_requests, :u_service_affecting
  end
end
