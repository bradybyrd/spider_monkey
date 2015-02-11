################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Preference < ActiveRecord::Base
  
  attr_accessible :insertion_point
  
  acts_as_list :scope => :user_id

  StepColumnlist = [
                "step_components_td",
                "step_servers_td",
                "step_task_td",
                "step_est_td",
                "step_assigned_to_td",
                "step_version_td"
              ]

  class << self
    
    def step_list_for(user)
      user_step_list_preferences = user.step_list_preferences
      Preference::StepColumnlist.each_with_index do |pref, index|
        step_pref = user_step_list_preferences.find_by_text(pref)
        unless step_pref
          user.step_list_preferences.create!(:text => pref, :position => index + 1,:preference_type=>"Step", :active => 't')
        end
      end
    end

    def reset_step_list_for(user)
      user.step_list_preferences.destroy_all unless user.step_list_preferences.nil?
      step_list_for(user)
    end   
  end

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
  
end
