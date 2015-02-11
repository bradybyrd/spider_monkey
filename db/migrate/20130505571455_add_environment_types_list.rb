class AddEnvironmentTypesList < ActiveRecord::Migration
  def self.up
    list_name = 'environment_types'
    list_items = %w(Generic Development Testing Production)

    # add the list items
    list_items.each_with_index do |list_item, index|
      ActiveRecord::Base.connection.execute <<-SQL
      Insert into #{list_name} (#{OracleAdapter ? "id, " : ""}name,description,position,created_at,updated_at) values( #{OracleAdapter ? "environment_types_seq.nextval, " : ""}'#{list_item}', 'A default environment type.', #{index + 1}, '#{Time.now.to_formatted_s(:db)}', '#{Time.now.to_formatted_s(:db)}')
      SQL
    end

  end

  def self.down
    list_name = 'environment_types'
    list_items = %w(Generic Development Testing Production)

    # remove each item
    list_items.each do |list_item|
      ActiveRecord::Base.connection.execute <<-SQL
      delete from #{list_name} where name='#{list_item}'
      SQL
    end
  end
end
