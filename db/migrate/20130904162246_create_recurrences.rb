class CreateRecurrences < ActiveRecord::Migration
  def change
    create_table :recurrences do |t|
      t.integer :id
      t.text :start_date
      t.text :end_time
      t.text :rrules
      t.text :exrules
      t.text :rtimes
      t.text :extimes

      t.timestamps
    end
  end
end
