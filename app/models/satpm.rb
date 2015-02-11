################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# == Schema Information
# Schema version: 20100113160249
#
# Table name: satpms
#
#  id                   :integer(38)     not null, primary key
#  script_argument_id   :integer(38)
#  script_argument_type :string(255)
#  property_id          :integer(38)
#  value_holder_id      :integer(38)     not null
#  created_at           :datetime
#  updated_at           :datetime
#  value_holder_type    :string(255)     not null
#

class Satpm < ActiveRecord::Base
  
  # This file was added because oracle doesn't allows table with big names (MAX 30 chars)
  
end
