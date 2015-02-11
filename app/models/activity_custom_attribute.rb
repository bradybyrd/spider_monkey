################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityCustomAttribute < ActivityAttribute

  validates :input_type,
            :presence => true,
            :inclusion => {:in => InputTypes}
  private

  def raw_values
    return [] unless current_activity
    current_activity.activity_attribute_values.find_all_by_activity_attribute_id(id).map(&:value)
  end
end
