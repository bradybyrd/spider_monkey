class AddUStreamStepLinkToChangeRequests2501 < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :u_streamstep_link, :string
  end

  def self.down
    remove_column :change_requests, :u_streamstep_link
  end
end
