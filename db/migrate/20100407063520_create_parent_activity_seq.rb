################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateParentActivitySeq < ActiveRecord::Migration
  
  def self.up
		if OracleAdapter
			begin
				ActiveRecord::Base.connection.execute "CREATE SEQUENCE PARENT_ACTIVITIES_SEQ INCREMENT BY 1 START WITH 10000"
				puts "CREATE SEQUENCE PARENT_ACTIVITIES_SEQ INCREMENT BY 1 START WITH 10000"
			rescue Exception => e
				puts "Failed: #{e.message}"
			end
		end
	end

  def self.down
		if OracleAdapter
			begin
				ActiveRecord::Base.connection.execute "DROP SEQUENCE PARENT_ACTIVITIES_SEQ"
				puts "DROP SEQUENCE PARENT_ACTIVITIES_SEQ"
			rescue Exception => e
				puts "Failed: #{e.message}"
			end
		end
	end

end

