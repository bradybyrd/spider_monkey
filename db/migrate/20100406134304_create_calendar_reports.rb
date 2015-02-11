################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateCalendarReports < ActiveRecord::Migration
  def self.up
    create_table :calendar_reports do |t|
      t.string  :team_name
      t.text    :report_url
      t.integer :user_id
      t.timestamps

    end
  end

  def self.down
    drop_table :calendar_reports
  end
end
