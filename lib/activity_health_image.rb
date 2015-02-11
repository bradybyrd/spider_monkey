################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActivityHealthImage
  Icons = { 'red'    => 'stop_small.png',
            'yellow' => 'exclamation_small.png',
            'green'  => 'check_small.png' }

  def activity_health_icon(health)
    Icons[health]
  end
end
