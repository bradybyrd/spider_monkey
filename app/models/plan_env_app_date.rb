################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanEnvAppDate < ActiveRecord::Base
  attr_accessible :app_id, :environment_id, :plan_id, :plan_template_id, :created_at, :created_by, :planned_start, :planned_complete
  belongs_to :plan
  belongs_to :environment
  belongs_to :app
  
  def self.between_to_from(startd, endd)
    startd = startd.to_date if startd.present?
    endd = endd.to_date if endd.present?
    
     where("( plan_env_app_dates.planned_start BETWEEN ? AND ? ) OR ( plan_env_app_dates.planned_complete BETWEEN ? AND ? ) OR "+
          "( plan_env_app_dates.planned_start <= ?  AND  plan_env_app_dates.planned_complete >= ? ) OR "+
          "(plan_env_app_dates.planned_complete is NULL AND plan_env_app_dates.planned_start <= ?) OR "+
          "(plan_env_app_dates.planned_complete is NULL AND plan_env_app_dates.planned_start is NULL)",
           startd, endd, startd, endd, endd, startd, endd) 
  end 

  def deletable?
    # See if there are requests that exist corresponding to this app_env_plan
    requests = Request.joins(:apps_requests).joins(:plan_member).
               select("distinct(requests.id)").
               where("requests.environment_id" => environment_id).
               where("apps_requests.app_id" => app_id).
               where("plan_members.plan_id" => plan_id)

    if requests.size == 0
      # Allow delete if there are no matching requests
      true
    else
      # Otherwise delete is not allowed
      false
    end
  end

end