class ChangeListRequestEstimatesHoursToMinutes < ActiveRecord::Migration
  def up
    list_items.each{ |li| li.update_attribute :value_num, li.value_num * 60 }
  end

  def down
    list_items.each{ |li| li.update_attribute :value_num, li.value_num / 60 }
  end

  def list_items
    List.find_by_name('RequestEstimates').list_items
  end

end
