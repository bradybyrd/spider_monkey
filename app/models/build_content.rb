################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BuildContent < ActiveRecord::Base
  belongs_to :plan
  belongs_to :query

  def self.add_build_contents(query, query_result, plan)
    self.destroy_all(:query_id => query.id)
    query_result.each do |build| 
      bc = BuildContent.new
      bc.query_id = query.id
      bc.plan_id = plan.id
      bc.object_i_d = build.object_i_d
      bc.message = build.message
      bc.status = build.status
      #bc.project = "#{build.project}"
      bc.save
    end
    query.update_attribute(:last_run_at, Time.now)
  end

end
