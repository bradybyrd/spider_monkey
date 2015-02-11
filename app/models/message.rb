################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :request

  attr_accessible :sender, :body, :request, :subject, :sender_id, :request_id
  
  validates :body,:presence => true
  validates :request,:presence => true
  validates :sender,:presence => true
end
