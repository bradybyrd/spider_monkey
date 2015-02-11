class AddParentRequestIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :parent_request_id, :integer
  end
end
