class AddOriginRequestTemplateIdToRequests < ActiveRecord::Migration
  def up
    add_column :requests, :origin_request_template_id, :integer
  end

  def down
    remove_column :requests, :origin_request_template_id
  end
end
