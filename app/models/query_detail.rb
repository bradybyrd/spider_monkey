################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class QueryDetail < ActiveRecord::Base
  
  # FIXME: Type in conjunction I think
  attr_accessible :query_id, :query, :query_element, :query_criteria, :query_term, :conjuction 
  
  belongs_to :query
end
