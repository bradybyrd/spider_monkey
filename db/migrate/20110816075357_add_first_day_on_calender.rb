class AddFirstDayOnCalender < ActiveRecord::Migration
  def self.up
    add_column :users, :first_day_on_calendar, :integer, :default => 0
  end

  def self.down
    remove_column :users, :first_day_on_calendar
  end
end
