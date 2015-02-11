################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ReleaseContent < ActiveRecord::Base
  
  # we have to protect against long data from Rally
  normalize_attribute :name, :with => {:truncate => {:length => 255} }
  normalize_attribute :owner, :with => {:truncate => {:length => 255} }
  normalize_attribute :project, :with => {:truncate => {:length => 255} }
  normalize_attribute :package, :with => {:truncate => {:length => 255} }
  normalize_attribute :description, :with => {:truncate => {:length => 255} }
  normalize_attribute :iteration, :with => {:truncate => {:length => 255} }
  normalize_attribute :release, :with => {:truncate => {:length => 255} }
  
  belongs_to :plan
  belongs_to :query
  
  scope :group_by_formatted_id, :group => "release_contents.formatted_i_d"
  scope :order_by_formatted_id, :order => "release_contents.formatted_i_d"
   
  def self.add_release_contents(query, query_result, plan)
    self.destroy_all(:query_id => query.id)
    query_result.each_with_index do |story, index| 
      rc = ReleaseContent.new
      rc.tab_id =  query.tab_id
      rc.query_id = query.id
      rc.plan_id = plan.id
      rc.formatted_i_d = story.formatted_i_d
      rc.name = story.name
      rc.schedule_state = story.schedule_state
      rc.owner = "#{story.owner}"
      rc.project = "#{story.project}"
      rc.package = story.package
      rc.description = story.description
      rc.creation_date = story.creation_date
      rc.last_update_date = story.last_update_date
      rc.accepted_date = story.accepted_date
      rc.iteration = "#{story.iteration}"
      rc.release = "#{story.release}"
      rc.save
    end
    query.update_attribute(:last_run_at, Time.now)
  end

end
