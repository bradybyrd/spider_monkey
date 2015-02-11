################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class DefaultTab < ActiveRecord::Base
  belongs_to :user

  attr_accessible  :user_id
  
  def self.my_default_tab(user, tab_name)
    default_tab = user.default_tab
    default_tab ||= DefaultTab.new(:user_id => user.id)
    default_tab.tab_name = tab_name
    default_tab.save
  end
end
