################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ProjectServer < ActiveRecord::Base
  
  has_many :workspace_projects, :class_name => "IntegrationProject", :conditions => ["object_i_d IS NOT NULL"]

  def authenticate # This method will be extended when other integrations will be done
    @slm = RallyRestAPI.new(
      :base_url => server_url,
      :username => username,
      :password => password,
      :version => 1.19) rescue nil
  end
  
  def cache_exists?
     File.exist? "#{RAILS_ROOT}/tmp/cache/views/project_tree_#{id}.cache"
  end
  
  def expire_cache_fragment!
    FileUtils.rm RAILS_ROOT + "/tmp/cache/views/project_tree_#{id}.cache", :force => true
  end
  
  def fetch_workspace_data
    # delay.save_projects!
    save_projects!
  end
  
  def save_projects!
    authenticate
    deactivate! and return unless @slm # Deactivate Integration if authentication failed
    @rally_projects = @slm.find_all(:project)
    parent_projects = []
    @rally_projects.collect {|p| parent_projects << p unless p.parent}
    parent_projects.each do |project|
      find_or_create_projects(project)
    end
    expire_cache_fragment! if cache_exists?
  end
  
  def find_or_create_projects(project, parent=nil)
    parent_project = if parent
      projects.find_or_create_by_name_and_object_i_d_and_parent_id(project.to_s, project.object_i_d, parent.id)
    else
      projects.find_or_create_by_name_and_object_i_d(project.to_s, project.object_i_d)
    end
    return unless project.children
    children = project.children
    if children
      children.each do |c|
        find_or_create_projects(c, parent_project)
      end
    end
  end
  
  #FIXME: Should this URL be hard coded, or should it ask the SLM?
  def find_iterations_by_project_object_i_d(object_i_d)
    authenticate
    return [] if @slm.blank?
    @iterations = @slm.find(:iteration, :pagesize => 200) {
      equal :project, "https://rally1.rallydev.com/slm/webservice/current/project/#{object_i_d}"
    }
  end
  
  #FIXME: Should this URL be hard coded, or should it ask the SLM?
  def find_releases_by_project_object_i_d(object_i_d)
    return [] if @slm.blank?
    @releases = @slm.find(:release, :pagesize => 200) {
      equal :project, "https://rally1.rallydev.com/slm/webservice/current/project/#{object_i_d}"
    }
  end
  
end
