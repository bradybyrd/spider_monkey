################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module PackageTemplatesHelper
  
  def template_property_value(template_item, property_value)
    return property_value.value if template_item.nil?
    if template_item["properties"][property_value.property.name].nil_or_empty?
      property_value.value
    else
      template_item["properties"][property_value.property.name]
    end
  end
  
end
