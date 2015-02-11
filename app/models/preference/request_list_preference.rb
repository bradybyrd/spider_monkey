################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Preference < ActiveRecord::Base
  
  attr_accessible :insertion_point
  
  acts_as_list :scope => :user_id
  
  Requestlist = [
                "request_name_td",
                "request_owner_td",
                "request_requestor_td",
                "request_business_process_td",
                "request_release_td",
                "request_app_td",
                "request_env_td",
                "request_deployment_window_td",
                "request_scheduled_td",
                "request_duration_td",
                "request_due_td",
                "request_steps_td",
                "request_created_td",
                "request_participants_td",
                "request_project_td",
                'request_package_contents_td',
                'request_team_td',
                'request_started_at_td'
              ]
  
  OriginalRequestlist = [
                "request_name_td",
                "request_owner_td",
                "request_requestor_td",
                "request_business_process_td",
                "request_release_td",
                "request_app_td",
                "request_env_td",
                "request_deployment_window_td",
                "request_scheduled_td",
                "request_duration_td",
                "request_due_td",
                "request_steps_td",
                "request_created_td",
                "request_participants_td",
                "request_project_td",
               'request_package_contents_td',
               'request_team_td'
              ]
  StepRequestColumnlist = [
                "request_name_td",
                "request_owner_td",
                "request_release_td",
                "request_plan_process_td",
                "request_app_td",
                "request_env_td",
                "request_deployment_window_td",
                "request_scheduled_td",
                "request_duration_td",
                "request_due_td",
                "request_steps_td",
                "request_created_td",
                "request_participants_td"
              ]

  RequestlistDataCols = {
                "env"=>"environment",
                "scheduled"=>"scheduled_at",
                "due"=>"target_completion_at",
                "steps"=>"executable_step_count",
                "created"=>"created_at"}

  class << self
    
    def request_list_for(user)
      
      # FIXME: If a user had legacy values and does not run the rake task, their dashboard will
      # have extra columns until they visit the preferences screen -- this routine prevented that
      # but was requested to be commented out until a more thorough review of this preference
      # system could be completed.  See Review 8632 in ccollab for discussion.
      # check for and destroy any legacy request preferences
      #user.request_list_preferences.each do |pref|
        #pref.destroy unless Preference::Requestlist.include?(pref.text)
      #end
      
      Preference::Requestlist.each_with_index do |pref, index|
        req_pref = user.request_list_preferences.find_by_text(pref)
        unless req_pref
           user.request_list_preferences.create!(:text => pref, :position => index + 1, :active => !( (pref == 'request_business_process_td') ||(pref == 'request_package_contents_td') ||(pref == 'request_project_td')||(pref == 'request_team_td') ))
        end
      end
    end

    def reset_request_list_for(user)
      user.request_list_preferences.destroy_all unless user.request_list_preferences.nil?
      request_list_for(user)
    end   
    
    def preference_key(item)
      idx = Preference::Requestlist.index(item)
      idx = Preference::OriginalRequestlist.index(item) if idx.nil?
      Preference::OriginalRequestlist[idx]
    end
  end
  
  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
  
end
