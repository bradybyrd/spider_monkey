################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class ActivitiesController < ApplicationController
  before_filter :authenticate_user!, :except => [:show_read_only]
  before_filter :get_deliverable, :only => [:modify_deliverable, :save_deliverable, :destroy_deliverable]
  before_filter :find_activity, :only => [:edit, :update, :destroy, :show_read_only]
  before_filter :activity_tab, :only => [:edit, :show_read_only]
  before_filter :clear_session, :only => :new

  def index
    redirect_to request_projects_path
  end

  def request_projects
    authorize! :list, Activity.new

    @activities = Activity.paginate(:include => [:requests => :executable_steps], :page => params[:page], :per_page => 25)
    @page_no = params[:page] || 1
    render :partial => "activities/request_projects" if request.xhr?
  end

  def new
    @activity_category = ActivityCategory.find params[:activity_category_id]
    @activity = Activity.new(:activity_category => @activity_category)

    authorize! :create, @activity
  end

  def edit
    authorize! :edit, @activity
  end

  def create
    params.merge!({:activity_creation_type => "activity_only"})
    ActiveRecord::Base.transaction do

      date_fields = [:projected_finish_at, :last_phase_end_on, :planned_start, :estimated_start_for_spend ]
      date_fields.each do |fld|
        params[:activity][fld] = reformat_date_for_save(params[:activity][fld]) if params[:activity][fld]
      end

      @activity = Activity.new params[:activity]

      authorize! :create, @activity

      @activity.user = current_user
      @activity.status = "Projected" #BJB hope here is appropriate
      if params[:activity_creation_type] == "activity_and_customer"
        @activity.should_have_app = true if params[:app_name_for_copy].blank?
      end

#     TODO: RF: Rails 3 - Attachment_fu plugin not compatible with Rails 3.
#     (params[:uploads] || []).each do |uploaded_data|
#        @activity.uploads.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
#     end



      if @activity.save
        if params[:activity_creation_type] == "activity_and_customer"
          @app_to_copy = App.find params[:app_id_to_copy]
          if(params[:shared_infrastructure])
            @activity.app = @app_to_copy.clone_new_app params[:app_name_for_copy]
          else
            @activity.app = @app_to_copy.clone_new_app params[:app_name_for_copy], @activity.id
          end
        end
        # To record Project creation in RecentActivity
#        current_user.log_activity(:context => "Project #{@activity.try(:name)} created") do

        #TODO: RF: Activity stream plugin no longer working with rails3
        act_link = activity_link(@activity.id)
#        current_user.log_activity(:context => "Project #{act_link} created") do
          @activity.update_attribute(:updated_at, @activity.updated_at)
#        end

        clear_session
        flash[:success] = "Project is successfully created."
        redirect_to activity_category_path(@activity.activity_category)
       else
        insert_session
        @activity_category = ActivityCategory.find(params[:activity][:activity_category_id])
        render :controller => 'activities', :action => :new
      end
    end
  end

  def show
    redirect_to :action => 'edit'
  end

  def show_read_only
    render :template => 'activities/edit'
  end

  def update
    authorize! :edit, @activity

    @activity.remove_custom_attr =  true
# TODO: RF: Rails 3 - Attachment_fu plugin not compatible with Rails 3.
#    @activity.uploads.destroy(@activity.uploads.find(params[:upload_for_deletion])) if params[:upload_for_deletion]
#    (params[:uploads] || []).each do |uploaded_data|
#      @activity.uploads.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
#    end
    # BJB 11-29-10 Cast all into USDate for save
    date_fields = [:projected_finish_at, :last_phase_end_on, :planned_start, :estimated_start_for_spend ]

    date_fields.each do |fld|
      params[:activity][fld] = reformat_date_for_save(params[:activity][fld]) if params[:activity][fld]
    end
    logger.info "SS__ Params before save: #{params[:activity].inspect}"
    if @activity.update_attributes(params[:activity])
      flash[:success] = "Project was saved successfully."
      @activity_tab = find_activity_tab(params[:activity_tab_id])
      if @activity_tab.name == "Notes"
        redirect_to edit_activity_path(@activity, :activity_tab_id => params[:activity_tab_id])
      else
        redirect_to activities_path
      end
    else
      @activity_tab = find_activity_tab(params[:activity_tab_id])
      render :action => :edit
    end
  end

  def destroy
    authorize! :delete, @activity

    @activity.destroy
    redirect_to activities_path
  end

  def creation_attributes
    @activity_category = ActivityCategory.find_by_id(params[:activity_category_id])
    render :partial => 'creation_attributes', :locals => { :activity_category => @activity_category }
  end

  def modify_deliverable
    authorize! :edit, @activity
    render :template => 'activities/widgets/deliverables/modify_deliverable', :layout => false
  end

  def save_deliverable
    authorize! :edit, @activity
    date_params = {
      :projected_delivery_date => params[:activity_deliverable][:projected_delivery_on],
      :delivered_date => params[:activity_deliverable][:delivered_on]
    }
    @deliverable.update_attributes(params[:activity_deliverable].merge(date_params))
    if @deliverable.errors.empty?
      render :template => 'activities/widgets/deliverables/save_deliverable'
    else
      render :template => 'activities/widgets/deliverables/invalid_deliverable'
    end
  end

  def destroy_deliverable
    authorize! :edit, @activity
    @deliverable.destroy
    render :template => 'activities/widgets/deliverables/save_deliverable'
  end

  def load_requests
    find_activity
    render :partial => "plans/release_calendar/requests", :locals => {:requests => @activity.requests}
  end

  private

  def find_activity_tab(tab_id)
    @activity.activity_tabs.find_by_id(tab_id) || @activity.activity_tabs.detect{ |tab| can?("edit_#{tab.name.downcase}".to_sym, @activity) }
  end

  def get_deliverable
    @activity = Activity.find(params[:id])
    @phase = @activity.activity_phases.find_by_id(params[:phase_id])

    if params[:deliverable_id].blank?
      @deliverable = @activity.deliverables.build :activity_phase => @phase
    else
      @deliverable = @activity.deliverables.find params[:deliverable_id]
    end
  end

  def find_activity
    begin
     @activity = Activity.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "#{ApplicationController.helpers.activity_or_project?} you are trying to access either does not exist or has been deleted"
      request.xhr? ? ajax_redirect(root_path) : redirect_to(root_path) && return
    end
  end

  def activity_tab
    @activity_tab = find_activity_tab(params[:activity_tab_id])
  end

  def insert_session
    session[:group] = Group.find(params[:activity][:leading_group_id]).try(:name) if params[:activity][:leading_group_id]
    session[:sponsor] = params["activity"]["custom_attrs"]["887"]
    session[:act_name] = params["activity"]["name"]
    session[:opportunity] = params["activity"]["problem_opportunity"]
    session[:estimated] = params["activity"]["estimated_start_for_spend"]
    session[:finish] = params["activity"]["projected_finish_at"]
    session[:budget] =  params["activity"]["budget_category"].present? ? params["activity"]["budget_category"] : "[None]"
    session[:type] = params["activity"]["custom_attrs"]["870"].present? ? params["activity"]["custom_attrs"]["870"] : "[None]"
    session[:srv_description] = params["activity"]["service_description"]
    session[:priority] = params["activity"]["custom_attrs"]["824"]
  end

  def clear_session
    session[:group] = ""
    session[:sponsor] = ""
    session[:act_name] = ""
    session[:opportunity] = ""
    session[:estimated] = ""
    session[:finish] = ""
    session[:budget] = ""
    session[:type] = ""
    session[:srv_description] = ""
    session[:priority] = ""
  end
end
