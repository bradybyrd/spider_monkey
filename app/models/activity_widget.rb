################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityWidget < ActivityAttribute
  def input_type
    'widget'
  end

  def widget?
    true
  end

  private

  def raw_values
    []
  end
end
