class UpdateRequestUpdatedAtForLastUpdateOnRequestData2501 < ActiveRecord::Migration
  def self.up
    connection.execute("UPDATE requests SET updated_at = (SELECT max(act_logs.created_at) FROM activity_logs act_logs WHERE act_logs.request_id = id)")
  end

  def self.down
    # NOTE: This migration can not be un done
  end
end