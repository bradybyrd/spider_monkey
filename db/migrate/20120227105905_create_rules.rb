class CreateRules < ActiveRecord::Migration
  def self.up
    create_table :rules do |t|
      t.string :name
      t.string :value_context
  end

  def self.down
    drop_table :rules
  end
  end
end
