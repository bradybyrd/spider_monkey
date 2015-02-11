################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddPresetItemsForRequestEstimatesListItems < ActiveRecord::Migration
  def up
    #EstimatesForSelect = ["1 hour", "1/2 day", "1 day", "2 days", "1 week", "weeks", "months"]
    request_estimates_items = [
        ['1 hour', 1], ['1/2 day', 12], ['1 day', 24],
        ['2 days', 48], ['1 week', 168], ['3 weeks', 504], ['2 months', 1440]
    ]

    list = List.create name: 'RequestEstimates', is_hash: true
    request_estimates_items.each do |list_item|
      ListItem.transaction do
        list_item = ListItem.new list_id: list.id, value_text: list_item[0], value_num: list_item[1]
        list_item.save! validate:false
      end
    end
  end

  def down
    list = List.find_by_name 'RequestEstimates'

    ListItem.where('list_id=?', list.id).delete_all
    list.delete
  end
end