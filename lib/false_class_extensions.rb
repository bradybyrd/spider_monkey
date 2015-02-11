################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module FalseClassExtensions
  def to_bool
    false
  end
  
  def nil_or_empty?
    false
  end
  
end
