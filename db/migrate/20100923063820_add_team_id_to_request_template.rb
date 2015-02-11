################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddTeamIdToRequestTemplate < ActiveRecord::Migration
  def self.up
    add_column :request_templates, :team_id, :integer
  end

  def self.down
    remove_column :request_templates, :team_id
  end
end
