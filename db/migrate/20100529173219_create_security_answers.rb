################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateSecurityAnswers < ActiveRecord::Migration
  def self.up
    create_table :security_answers do |t|
      t.integer :question_id
      t.integer :user_id
      t.string  :answer
      t.timestamps
    end
  end

  def self.down
    drop_table :security_answers
  end
end
