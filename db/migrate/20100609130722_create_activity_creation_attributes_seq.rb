################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateActivityCreationAttributesSeq < ActiveRecord::Migration
  def self.up
    if OracleAdapter
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE aca_seq INCREMENT BY 1 START WITH 10000")
    elsif AdapterName == "PostgreSQL"
      ActiveRecord::Base.connection.execute("ALTER TABLE activity_creation_attributes_id_seq RENAME to aca_seq")
    end
  end

  def self.down
    # Irreversible
    # If aca_seq is dropped then it will error because 
    # set_sequence_name "aca_seq" is still present in models/activity_creation_attribute.rb
  end
end
