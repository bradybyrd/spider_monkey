################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityStaticAttribute < ActivityAttribute
  
  validates :field,
            :presence => true,
            :inclusion => {:in => Activity.column_names}
  validates :input_type, 
            :presence => true,
            :inclusion => {:in => InputTypes}
          
  def from_system?
    field.try(:=~, /_ids?$/).to_bool
  end

  def static?
    true
  end

  private

  def raw_values
    #BJB Force array to 1 element for static fields
    values = current_activity.try(field)
    values = values.to_s if date?
    if field.include? "_id"
      returnval = Array(values)
    else
      returnval = Array(0)
      returnval[0] = values
    end
    return returnval
  end
end
