class ActivitiesController < ApplicationController
  before_filter :authenticate_user!, :except => [:show_read_only]
  before_filter :requires_permission_to_edit_activities, :only => [:new, :create, :creation_attributes]
  before_filter :requires_admin, :only => [:destroy]
  before_filter :get_deliverable, :only => [:modify_deliverable, :save_deliverable, :destroy_deliverable]
  before_filter :find_activity, :only => [:edit, :update, :destroy, :show_read_only]
  before_filter :requires_permission_to_edit_this_activity,
                :only => [:show, :edit, :update, :destroy, :modify_deliverable, :save_deliverable, :destroy_deliverable]
  before_filter :activity_tab, :only => [:edit, :show_read_only]

  def index
    if true
      set_activities_filters
      @expand_all = params[:expandAll] if params[:expandAll].present?
      respond_to do |format|
        format.html {render :template => "activities/index", :layout => "layouts/application"}
        format.xml  {render :template => "activities/index"}
      end
    else
      redirect_to request_projects_path
    end
  end
  
  def load_activities_grid
    params.merge!({:id => params[:id].split("group_").last})
    @group = Group.find(params[:id])
    @group_id = @group.id
    set_activities_filters
    respond_to do |format|
      format.xml {render :template => "activities/load_activities_grid"}
    end
  end

  def request_projects
    @activities = Activity.all
  end

  def new
    @activity_category = ActivityCategory.find params[:activity_category_id]
    @activity = Activity.new
  end

  def edit
    @current_year = $system_settings["budget_year"] ? $system_settings["budget_year"].to_i : Date.today.year
  end

  def create
    ActiveRecord::Base.transaction do
      params[:activity][:estimated_start_for_spend] = reformat_date_for_save(params[:activity][:estimated_start_for_spend])
      params[:activity][:projected_finish_at] = reformat_date_for_save(params[:activity][:projected_finish_at]) if params[:activity][:projected_finish_at].present?                
      @activity = Activity.new params[:activity]
      @activity.user = current_user
      @activity.status = "Projected" #BJB hope here is appropriate
      if params[:activity_creation_type] == "activity_and_customer"
        @activity.should_have_app = true if params[:app_name_for_copy].blank?
      end
      
      (params[:assets] || []).each do |uploaded_data|
        @activity.assets.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
      end
      
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
        current_user.log_activity(:context => "#{activity_link(@activity.id)} created") do 
          Activity.skip_callback(:remove_custom_attrs) do 
            @activity.update_attribute(:updated_at, @activity.updated_at)
          end
        end
        
        @activity.set_unassigned_parent if @activity.parent_activities.blank?
        flash[:success] = "Activity created successfully."
        if SystemSetting.portfolio_enabled?
          ajax_redirect activities_path(:activity_category_id => @activity.activity_category_id)
        else
          clear_session
          redirect_to activities_path(:activity_category_id => @activity.activity_category_id)
        end
      else
        if SystemSetting.portfolio_enabled?
          show_validation_errors(:activity)
        else
          insert_session
          @activity_category = ActivityCategory.find(params[:activity][:activity_category_id])
          render :controller => 'activities', :action => :new
        end
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
    @activity.assets.destroy(@activity.assets.find(params[:asset_for_deletion])) if params[:asset_for_deletion]

    (params[:assets] || []).each do |uploaded_data|
      @activity.assets.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
    end
    
    params[:activity][:projected_finish_at] = reformat_date_for_save(params[:activity][:projected_finish_at]) if params[:activity][:projected_finish_at].present?
    params[:activity][:last_phase_end_on] = reformat_date_for_save(params[:activity][:last_phase_end_on]) if params[:activity][:last_phase_end_on].present?
    params[:activity][:estimated_start_for_spend] = reformat_date_for_save(params[:activity][:estimated_start_for_spend]) if params[:activity][:estimated_start_for_spend].present?
         
    if @activity.update_attributes(params[:activity])
      @activity.expire_cache_fragment
      @activity.set_unassigned_parent if @activity.parent_activities.blank?
      flash[:success] = "Activity was saved successfully."
      if SystemSetting.portfolio_enabled?
        ajax_redirect edit_activity_tab_path(@activity, params[:activity_tab_id])
      else
        redirect_to edit_activity_tab_path(@activity, params[:activity_tab_id])
      end
    else
      if SystemSetting.portfolio_enabled?
        show_validation_errors(:activity)
      else
        @activity_tab = find_activity_tab(params[:activity_tab_id])
        render :action => :edit
      end
    end
  end

  def destroy
    @activity.destroy
    if request.xhr?
      render :nothing => true
    else
      redirect_to activity_category_path(@activity.activity_category_id)
    end
  end

  def creation_attributes
    @activity_category = ActivityCategory.find_by_id(params[:activity_category_id])
    render :partial => 'creation_attributes', :locals => { :activity_category => @activity_category }
  end

  def modify_deliverable
    render :template => 'activities/widgets/deliverables/modify_deliverable', :layout => false
  end

  def save_deliverable
    params[:activity_deliverable][:projected_delivery_on] = reformat_date_for_save(params[:activity_deliverable][:projected_delivery_on]) if params[:activity_deliverable][:projected_delivery_on].present?
    params[:activity_deliverable][:delivered_on] = reformat_date_for_save(params[:activity_deliverable][:delivered_on]) if params[:activity_deliverable][:delivered_on].present?
    @deliverable.update_attributes(params[:activity_deliverable])
    if @deliverable.errors.empty?
      render :template => 'activities/widgets/deliverables/save_deliverable'
    else
      render :template => 'activities/widgets/deliverables/invalid_deliverable'
    end
  end

  def destroy_deliverable
    @deliverable.destroy
    render :template => 'activities/widgets/deliverables/save_deliverable'
  end

  private

  def find_activity_tab(tab_id)
    @activity.activity_tabs.find_by_id(tab_id) || @activity.activity_tabs.first
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

  def requires_permission_to_edit_activities
    #redirect_to root_path unless current_user.can_edit_activities?
  end

  def requires_permission_to_edit_this_activity
    if @activity
      redirect_to root_path unless current_user.can_edit_activity?(@activity)
    end
  end

  def find_activity
    @activity = Activity.find params[:id]
  end

  def activity_tab
    @activity_tab = find_activity_tab(params[:activity_tab_id])
  end
  
  def session_var
    "activity_filters_#{@activity_category.id}".to_sym
  end
  
  def set_activities_filters
    @activity_category = if params[:activity_category_id].present?
      ActivityCategory.find(params[:activity_category_id])
    else
      ActivityCategory.default
    end
    respond_to do |format|
      format.html {
    
        @params = params
        session[session_var] ||= HashWithIndifferentAccess.new
        if params[:filters].present?
          session[session_var] = params[:filters]
          session[session_var] = session[session_var].merge!({"status_filter" => ""}) unless session[session_var].key?("status_filter")
        else
          if params[:clear_filters].present?
            session[session_var] = {} 
            session[session_var] = session[session_var].merge!({"status_filter" => ""})
          end  
          unless session[session_var].key?("status_filter")
            session[session_var] = session[session_var].merge!({"status"=>["On Hold", "Ongoing", "Projected"]})
          end
        end
        session["#{session_var}_search"] = params[:key] if params[:key].present?
        if params["clear_activity_filters_#{@activity_category.id}_search"].present?
          session["#{session_var}_search"] = nil
        end
    }
    format.xml {
      activities_data
    }
  end
  end
  
  def activities_data # TODO - Sri - Clean up to minimize lines and put in model
    activities = @activity_category.activities
    logger.info "SS__ Getting activities data"
    session[session_var].delete_if{|key, value| key == "status_filter"}
    
    # Collect custom activity attribute ids
      custom_attribute_filters = session[session_var].reject{|k,v| !k.match(/[A-Za-z]+/).blank?} 
    # Remove custom activity attribute ids from fitlers_hash
      session[session_var].reject!{|k,v| k.match(/[A-Za-z]+/).blank?} 
      
    if session[session_var].present? and session[session_var].key?("manager_id")         
      manager_values = session[session_var]["manager_id"]
      session[session_var] = session[session_var].delete_if{|key, value| key == "manager_id"}
      @unassigned_managers = true
    end         
    
    if session[session_var].present? and (session[session_var].has_key?("blockers") || session[session_var].has_key?("theme"))
      filters_hash = session[session_var]
      blocker = filters_hash[:blockers]
      theme = filters_hash[:theme]
      blocker_conds = Activity.filter_with_blockers(blocker) if filters_hash[:blockers].present?
      theme_conds = Activity.filter_with_theme(theme, blocker_conds) if filters_hash[:theme].present?
      filter_hash_new = filters_hash.delete_if {|key,value| key == "blockers"} 
      filter_hash_new = filters_hash.delete_if {|key,value| key == "theme"} 
      activities = activities.name_order.filter_by(filter_hash_new, current_user.admin? ? true :false)
      conds = (blocker_conds || "") + (theme_conds || "")
      unless conds.blank?
        activities = Activity.id_equals(activities.all(:select =>"id", :conditions => conds).map(&:id))
      end
      filters_hash["blockers"] = blocker if blocker
      filters_hash["theme"] = theme if theme
    else
      activities = activities.name_order.filter_by(session[session_var] || {}, current_user.admin? ? true :false)
    end
    unless custom_attribute_filters.blank?
      activities = activities.filter_by_custom_attributes(custom_attribute_filters)
    end
    if @unassigned_managers
      session[session_var].merge!({"manager_id" => manager_values})
      activities = activities.filter_by_unassigned_managers(manager_values)
    end    
    if session["#{session_var}_search"].present?
      condition = session["#{session_var}_search"].strip
      conds = ["LOWER(activities.name) LIKE ? OR activities.id = ?", '%' + condition.downcase + '%', condition.to_i]
      activities = activities.all(:conditions => conds)
    end
    if @group_id
      activities = Activity.fetch_by_group(@activity_category.id, @group_id, (current_user.present? && current_user.admin?), activities.map(&:id))
    end
    @groups = Group.find_all_by_id(activities.map(&:leading_group_id).uniq)
    @activities = activities.group_by(&:leading_group_id)
    session[session_var].merge!(custom_attribute_filters)
    session[session_var].merge!({"status_filter" => ""})
    logger.info "SS__ Getting activities data-end"
     
  end
  
end


