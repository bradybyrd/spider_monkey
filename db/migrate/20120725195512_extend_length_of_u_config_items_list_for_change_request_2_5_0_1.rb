class ExtendLengthOfUConfigItemsListForChangeRequest2501 < ActiveRecord::Migration
  def self.up
    change_column :change_requests, :u_config_items_list, :string, :limit => 2000
  end

  def self.down
    # NOTE: This will fail if data has been added longer than 255 -- correct database first
    puts "\n\nWARNING: Rolling back migration will fail if u_config_items_list has data > 255 chars.\nTruncate the data and then rerun the rake db:rollback task."
    change_column :change_requests, :u_config_items_list, :string, :limit => nil
  end
end