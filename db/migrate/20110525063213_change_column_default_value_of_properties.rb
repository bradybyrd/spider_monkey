################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeColumnDefaultValueOfProperties < ActiveRecord::Migration
  def self.up
		if OracleAdapter
			connection.execute("ALTER TABLE properties ADD (default_value_varchar VARCHAR2(255 CHAR) )")
			connection.execute("UPDATE  properties SET default_value_varchar = DBMS_LOB.SUBSTR(default_value)")
			remove_column :properties, :default_value
			rename_column :properties, :default_value_varchar, :default_value
		else
			change_column :properties,  :default_value, :string
		end
  end

  def self.down
		if OracleAdapter
			connection.execute("ALTER TABLE properties ADD (default_value_clob CLOB )")
			connection.execute("UPDATE  properties SET default_value_clob = default_value")
			remove_column :properties, :default_value
			rename_column :properties, :default_value_clob, :default_value
		else
			change_column :properties,  :default_value, :text
		end
	end
end

