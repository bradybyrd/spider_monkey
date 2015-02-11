################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ReleaseContentItem < ActiveRecord::Base
  
  ScheduleState = List.get_list_items("ReleaseContentItemState")
  
  include SoftDelete
  
  belongs_to :plan
  belongs_to :integration_project
  belongs_to :integration_release
  
  has_many :steps_release_content_items
  has_many :request_steps, :class_name => "Step", :through => :steps_release_content_items
  
  has_many :steps, :foreign_key => :custom_ticket_id
  
  scope :active, where("release_content_items.active" => true)
  scope :inactive, where("release_content_items.active" => false)
  
  scope :name_order, :order => "release_content_items.name ASC"
  
  scope :custom_tickets, where("release_content_items.tab_id" => 2)
  scope :custom_release_content_tags, where("release_content_items.tab_id" => 1)
  scope :show_in_steps, where("release_content_items.show_in_step" => true)
  
  validates :name, :presence => true
  validates :description, :presence => true
  
  def state
    schedule_state.titleize if item_state
  end
  
end
