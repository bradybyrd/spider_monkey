################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ResourcesController < ApplicationController
  before_filter :requires_resource_manager
  before_filter :find_resource, :only => [:allocate, :shift_workstreams, :update_workstreams, :remove_workstream]
  before_filter :collect_group_data, :only => [:my_resources, :update_workstreams, :remove_workstream] #, :allocations_by_group]
  before_filter :collect_allocations, :only => [:update_workstreams,:remove_workstream]
  before_filter :collect_groups, :only => [:index, :group_allocations]
  before_filter :collect_resources_by_group, :only => [:my_resources, :index] #, :allocations_by_group]
 # before_filter :collect_placeholders_by_group, :only => [:my_resources, :index]
  before_filter :collect_allocations, :only => [:my_resources, :index, :group_allocations]
  
  def index; end

  def my_resources
    render :template => 'resources/index'
    #logger.debug "BJB Session: #{session.inspect}"
    session[:status] = "close"
  end
  
  def resources #All - 
    @resources[@group.id] = @group.resources.index_order
  end

  def new
    @placeholder = PlaceholderResource.new
    @groups = group_source.name_order
    render :layout => false
  end

  def create
    placeholder = PlaceholderResource.new params[:placeholder_resource]
    placeholder.roles = params[:placeholder_resource][:roles]
    placeholder.save!
    redirect_to my_resources_path
  end

  def edit
    @placeholder = PlaceholderResource.find_by_id(params[:id])
    @groups = group_source.name_order
    render :layout => false
  end

  def update
    placeholder = PlaceholderResource.find_by_id(params[:id])
    placeholder.roles = params[:placeholder_resource][:roles]
    placeholder.update_attributes(params[:placeholder_resource])
    redirect_to :action => :index
  end

  def allocate
    set_month_offsets
    collect_available_activities
    render :layout => false
  end

  def destroy
    current_user.placeholder_resources.find(params[:id]).destroy
    redirect_to my_resources_path
  end

  def shift_workstreams
    set_month_offsets
    collect_available_activities
  end

  def update_workstreams
    @resource.add_workstreams params[:activity_ids]
    @resource.update_allocations params[:allocations]
    set_month_offsets
    collect_available_activities
    @close_facebox = params[:save_and_close].to_bool
    flash.now[:success] = 'Workstreams updated.'
  end

  def remove_workstream
    @resource.workstreams.find_by_id(params[:workstream_id]).try(:destroy)
    set_month_offsets
    collect_available_activities
    render :template => 'resources/update_workstreams'
  end
  
  def group_allocations
    render :update do |page|
      session[:status] = [] if session[:status].blank?
      @groups.each do |group| 
        session[:group_id] = [] if session[:group_id].blank?
        if params[:status] == "expand" 
          session[:group_id] << group.id
          @placeholder_resources = Array.new
          @resources = Array.new
          session[:group_id].each do |id|
            group = Group.find_by_id(id)
            @placeholder_resources[id.to_i] = group.placeholder_resources.active unless group.blank?
            @resources[id.to_i] = group.resources.active.not_placeholder.index_order unless group.blank?
          end
          session[:status] = "close"
          page.replace_html "resource_allocation_#{group.id}", :partial => "resource_allocations", :locals => {:group => group}
          page << "$('#toggle_group_'+#{group.id}).removeClass('toggle closed preserve resource');$('#toggle_group_'+#{group.id}).addClass('toggle open preserve resource');"
          page.replace_html "link", :partial => "link_close"
        else
          session[:group_id] = []
          session[:status] = "expand"
          page.replace_html "resource_allocation_#{group.id}", ""
          page << "$('#toggle_group_'+#{group.id}).removeClass('toggle open preserve resource');$('#toggle_group_'+#{group.id}).addClass('toggle closed preserve resource');"
          page.replace_html "link", :partial => "link_expand"
        end
      end
    end
    #logger.debug "Group Allocations - Session Vars"
    #logger.debug session.inspect
  end
  
  def allocations_by_group
   
   #@group = group_source.find(params[:id])
   @group = Group.find(params[:id]) #BJB See but not allocate
   @resources = Array.new
   #4-9-10@placeholder_resources = Array.new
   @team_allocations = Array.new
   if params[:sortable].blank?
     @resources
     #4-9-10@placeholder_resources
     session[:group_id] = [] if session[:group_id].blank?
     group_id = params[:id].to_i
     if session[:group_id].include?(group_id)
       session[:group_id].delete(group_id)
     else   
       session[:group_id] << group_id
     end
   else
     session[:group_id] << group_id
     if session[:sort].blank?
      session[:sort] = "ASC"
     else
      if session[:sort] == "DESC"
        session[:sort] = "ASC" 
      else
        session[:sort] = "DESC"
      end
     end 
     if params[:status].blank?
       if current_user.admin
        @resources[@group.id] = @group.resources.active.not_placeholder.find(:all, :order => "#{params[:sortable]} #{session[:sort]}")
       else
        @resources[@group.id] = @group.resources.active.not_placeholder.find(:all, :order => "#{params[:sortable]} #{session[:sort]}")
       end
       #4-9-10@placeholder_resources
      else
       resources
       #4-9-10@@placeholder_resources[@group.id] = @group.placeholder_resources.find(:all, :order => "#{params[:sortable]} #{session[:sort]}")
     end
   end
   
   unless session[:group_id].include?(group_id)
     logger.debug "BJB Session Groups(not): #{session.inspect}"
     render :update do |page|   
       page.replace_html "resource_allocation_#{@group.id}", ""
       page << "$('#toggle_group_'+#{@group.id}).removeClass('toggle open preserve resource');$('#toggle_group_'+#{@group.id}).addClass('toggle closed preserve resource');"
     end
   else
     logger.debug "BJB Session Groups(else): #{session.inspect}"
     #4/2/10 BJB Get all allocations at once
     collect_resources_by_group
     @team_allocations = ResourceAllocation.allocation_pivot(@group.id)
     render :update do |page|      
       page.replace_html "resource_allocation_#{@group.id}", :partial => "resource_allocations", :locals => {:group => @group}
       page << "$('#toggle_group_'+#{@group.id}).removeClass('toggle closed preserve resource');$('#toggle_group_'+#{@group.id}).addClass('toggle open preserve resource');"
       if !params[:sortable].blank?
         if session[:sort] == "DESC"
           page << "$('##{params[:sortable].downcase}_'+#{@group.id}).attr('class', 'asc')"
         else
           page << "$('##{params[:sortable].downcase}_'+#{@group.id}).attr('class', 'desc')"
         end
       end
     end
   end
  end

  protected 
  
  def find_resource
    @resource = resource_source.find_by_id(params[:id])    
    unless @resource
      flash[:error] = "You may only edit resources under your management."
      redirect_to my_resources_path
      false
    end
  end
  
  def collect_groups
    @groups = Group.name_order.active
  end

  def collect_group_data
    @groups = group_source.name_order
    
  end

  def collect_allocations
    @team_allocations = ResourceAllocation.allocation_pivot(-1)
  end
  
  def group_source
    current_user.admin? ? Group.active : current_user.managed_groups.active
  end

  def resource_source
    current_user.managed_resources_including_placeholders.index_order
  end

  def collect_available_activities
    @available_activities = Activity.active_activities.available_for_user(@resource).name_order
  end

  def set_month_offsets
    @month_offset = params[:month_offset].to_i
    @months_ago = 5 - @month_offset
    @months_from_now = 6 + @month_offset
  end
  
  def collect_resources_by_group
    @resources = Array.new
    session_group_id
    session[:group_id].each do |id|
      group = Group.find_by_id(id)
      @resources[id.to_i] = group.resources.active.index_order unless group.blank?
    end
  end
  
  def collect_placeholders_by_group
    @placeholder_resources = Array.new
    session_group_id
    session[:group_id].each do |id|
      group = Group.find_by_id(id)
      @placeholder_resources[id.to_i] = group.placeholder_resources.active unless group.blank?
    end
  end
  
  def placeholder_resources
    @placeholder_resources[@group.id] = @group.placeholder_resources
  end
  
  def session_group_id
    session[:group_id] = [] if session[:group_id].blank?
  end
  
    
  
end
