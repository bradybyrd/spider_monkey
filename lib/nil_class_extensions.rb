################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module NilClassExtensions
  def to_bool
    false
  end
  
  def nil_or_empty?
    true
  end
  
  def to_i
    nil
  end
  
  def [] *args
    false
  end
  
  def join *args
    []
  end
  
  def format; ''; end
  
end
