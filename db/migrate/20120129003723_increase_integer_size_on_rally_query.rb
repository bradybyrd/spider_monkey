class IncreaseIntegerSizeOnRallyQuery < ActiveRecord::Migration
  def self.up
    # typical numbers for Rally tickets might be 5220362597 which is 
    # larger than int4 in postgres and will throw an out of bounds error
    # unfortunated the postgres adapter interprets limit is bit and give
    # you a 64 bit (int8) field, while Oracle interprets it literally
    # and gives you a smaller than usual tiny int like thing
    if PostgreSQLAdapter || MySQLAdapter
      change_column :queries, :rally_iteration_id, :integer, :limit => 8
      change_column :queries, :rally_release_id, :integer, :limit => 8
    elsif OracleAdapter
      # this gives you an oracle number with no 38 bit limit
      change_column :queries, :rally_iteration_id, :float, :precision => 64, :scope => 0
      change_column :queries, :rally_release_id, :float, :precision => 64, :scope => 0
    else
      change_column :queries, :rally_iteration_id, :integer, :limit => 8
      change_column :queries, :rally_release_id, :integer, :limit => 8
    end
  end

  def self.down
    # once there is data in the database at limit 8, this will throw an 
    # error when it tries to shrink the field.  Only roll back on unchanged
    # databases with no 8 bit integers in there fields, nil should trigger default
    change_column :queries, :rally_iteration_id, :integer, :limit => nil
    change_column :queries, :rally_release_id, :integer, :limit => nil
  end
end
