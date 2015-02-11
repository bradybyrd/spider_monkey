class AddReleaseNotesToChangeRequest2501 < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :u_release_notes, :text
  end

  def self.down
    remove_column :change_requests, :u_release_notes
  end
end
