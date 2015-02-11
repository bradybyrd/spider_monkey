class AddTypeToChangeRequest2501 < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :cr_type, :string
  end

  def self.down
    remove_column :change_requests, :cr_type
  end
end
