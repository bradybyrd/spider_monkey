################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActiveRecordAssociationsExtensions
  def clear_assoc_objects(assoc={})
    assoc.each_pair{ |assoc_object, assoc_ids| eval("#{assoc_object}.clear") if assoc_ids.blank? }
  end
end

ActiveRecord::Base.send(:include, ActiveRecordAssociationsExtensions)
