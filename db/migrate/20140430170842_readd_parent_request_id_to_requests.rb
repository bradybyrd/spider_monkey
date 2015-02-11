class ReaddParentRequestIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :parent_request_id, :integer unless column_exists? :requests, :parent_request_id, :integer
  end
end