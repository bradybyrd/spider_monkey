require 'active_record/fixtures'

class AddPermissionsList < ActiveRecord::Migration
  def up
    # skip
  end

  def down
    Permission.delete_all
  end
end
