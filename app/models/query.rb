################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Query < ActiveRecord::Base
  
  attr_accessible :name, :project, :iteration, :plan, :plan_id, :project_server, :project_server_id, :script, :script_id, :user, :last_run_by, :release_contents, :release, :query_details
  
  # we have to protect against long data from Rally
  normalize_attribute :name, :with => {:truncate => {:length => 255} }
  normalize_attribute :project, :with => {:truncate => {:length => 255} }
  normalize_attribute :iteration, :with => {:truncate => {:length => 255} }
  normalize_attribute :release, :with => {:truncate => {:length => 255} }
  normalize_attribute :rally_project_id, :with => {:truncate => {:length => 255} }
  normalize_attribute :rally_data_type, :with => {:truncate => {:length => 255} }
  normalize_attribute :artifacts, :with => {:truncate => {:length => 255} }

  belongs_to :plan
  belongs_to :project_server
  belongs_to :script
  belongs_to :user, :foreign_key => "last_run_by"
  
  has_many :release_contents, :dependent => :destroy
  has_many :query_details, :dependent => :destroy
  has_many :build_contents, :dependent => :destroy
  has_many :change_requests, :dependent => :destroy

  concerned_with :service_now
  
  SERVER = { "Rally" => 1, "Jira" => 2}
  
  scope  :release_contents_queries, where("rally_data_type = 'ReleaseContent' or rally_data_type NOT IN ('Build') or rally_data_type IS NULL")
  
  scope :build_contents_queries, where('rally_data_type' => 'Build')
  
  scope :active, joins(:project_server).where("project_servers.is_active" => true)
  scope :not_running, where(:running => false)
  scope :running, where(:running => true )
  
  scope :mapped_to_ticketing, joins(:script).where('scripts.maps_to' => 'Ticket', 'scripts.render_as' => 'Table')
  
  before_save :write_user_attributes
  
  def is_of_service_now?
    rally_data_type == "ChangeRequest"
  end
  
  def details
    qd = is_of_service_now? ? "" : []
    if is_of_service_now?
      conjunctions = query_details.map(&:conjuction)
    else
      qd << "Project = " + self.project if project
      qd << "Release = " + self.release if release
      qd << "Iteration = " + self.iteration if iteration
      qd << "Artifacts = " + self.artifacts if artifacts
    end
    query_details.each_with_index do |query_detail, index|
      qd << "#{query_detail.query_element} #{query_detail.query_criteria} #{query_detail.query_term}"
      qd << " #{conjunctions[index + 1]} " unless conjunctions.blank?
    end
    is_of_service_now? ? qd : qd.join(", ")
  end
  
  # a method for limiting the length of the menu_label
  def select_label
    if name.length > 70
      name[0...70] + '...'
    else
      name
    end
  end
  
  private
  
  def write_user_attributes
    write_attribute(:last_run_by, User.current_user.id) if User.current_user
    write_attribute(:last_run_at, Time.now)
  end


end
