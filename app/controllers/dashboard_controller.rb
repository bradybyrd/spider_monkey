################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class DashboardController < ApplicationController

  before_filter :dashboard_setup, :only => [:promotions]
  skip_before_filter :verify_authenticity_token, :only => [:self_services]

  def self_services
    authorize! :view, :dashboard_tab
    index
  end

  def recent_activities
    get_recent_activities
    @page_no = params[:page] || 1
    if params[:pagination].present?
      if @recent_activities.blank?
        render :text => "No recent activity found"
      else
        render :partial => "dashboard/self_services/recent_activity"
      end
    elsif @page_no == 1
      render :layout => false
    else
      render :partial => "dashboard/recent_activities_table"
    end
  end

  def recent_requests
    params.merge!({:request_ids => params[:request_ids].split(',')}) unless params[:request_ids].is_a? Array
    @request_ids = params[:request_ids]
    @page_path = recent_requests_path(:request_ids => params[:request_ids])
    @requests = Request.id_in(@request_ids.collect { |id| id.to_i - GlobalSettings[:base_request_number] })
    get_data
    paginate_requests

    RequestApplicationEnvironmentPreloader.new(@requests).preload

    if request.xhr?
      render :partial => "dashboard/self_services/requests"
    else
      render :template => "dashboard/index"
    end
  end

  def index
    if request.xhr?
      @request_dashboard = request_dashboard_data
      @request_dashboard[:page_path] = root_path
      render partial: 'dashboard/self_services/requests'
    else
      @request_dashboard = dashboard_data
      render template: 'dashboard/self_services'
    end
  end

  def request_dashboard
    authorize! :view, :requests_tab

    @request_dashboard = request_dashboard_data
    @request_dashboard[:page_path] = request_dashboard_path

    if request.xhr?
      render partial: 'dashboard/self_services/requests'
    else
      render action: :index
    end
  end

  def promotions
    authorize! :view, :dashboard_promotions

    @request_dashboard = request_dashboard_data
    @request_dashboard[:page_path] = promotion_requests_path

    if request.xhr?
      render :partial => "dashboard/self_services/promotions"
    else
      my_applications_without_authorization
      render :template => "dashboard/self_services"
    end
  end

  def steps_for_request_ajax
    @request = Request.find(params[:request_id], :include => [:owner])
    steps = @request.executable_steps.includes(:owner, :steps, :parent).sort { |s1, s2| s1.number_real <=> s2.number_real }
    filters = session[params[:session_filter_var]] || {}
    steps = steps.owned_by_group(filters[:group_id]) if filters[:group_id].present?
    if filters[:user_id].present?
      if filters[:include_groups] == 'true'
        steps = steps.owned_by_user_including_groups(filters[:user_id])
      else
        steps = steps.owned_by_user(filters[:user_id])
      end
    end
    @request_active_list_preferences = current_user.request_list_preferences.active.flatten

    render :partial => 'steps/dashboard_list', :locals => {:req => @request, :steps => steps}
  end

  def my_applications
    authorize! :view, :my_applications
    my_applications_without_authorization
  end

  def my_environments
    authorize! :view, :my_environments
    @my_environments = paginate_records(current_user.accessible_environments, params, 6)
    @page_no = params[:page] || 1
    render :partial => "dashboard/self_services#{params[:page].present? ? '/tables' : ''}/my_environments" if request.xhr?
  end

  def my_servers
    authorize! :view, :my_servers
    servers = current_user.accessible_servers.active.includes(environments: :apps)
    @my_servers = paginate_records(servers, params, 6)
    @page_no = params[:page] || 1
    render :partial => "dashboard/self_services#{params[:page].present? ? '/tables' : ''}/my_servers" if request.xhr?
  end

  private

  def paginate_requests
    per_page = @filters[:per_page].blank? ? 20 : @filters[:per_page].to_i

    if @filters[:sort_scope] == "executable_step_count"
      args_hash = {:page => params[:page], :per_page => per_page, :total_entries => @requests.size}
    else
      args_hash = {:page => params[:page], :per_page => per_page, :count => {:select => "distinct requests.id"}}
    end

    args_hash.merge!({:order => "requests.id #{current_user.list_order}"}) unless @filters[:sort_scope].present?

    @requests = @requests.paginate(args_hash)
  end

  def get_recent_activities
    @recent_activities = paginate_records(current_user.related_recent_activity.uniq, params, 3)
  end

  def limit_to_last_90_days(requests, filter_or_search)
    return requests if filter_or_search
    start_date = Time.zone.now - 90.days
    requests.where('requests.updated_at > ?', start_date)
  end

  def my_applications_without_authorization
    apps = current_user.accessible_apps.includes(:environments).order('apps.name')
    per_page = 6
    page = request.xhr? ? params[:page] : 1
    @my_applications = paginate_records(apps, params, per_page, page)
    @page_no = params[:page] || 1
    set_application_permissions

    render partial: "dashboard/self_services#{params[:page].present? ? '/tables' : ''}/my_applications" if request.xhr?
  end

  def set_application_permissions
    @view_my_applications = can? :view, :my_applications
    @can_update_app = {}
    @can_edit_app = {}
    @my_applications.each do |application|
      @can_update_app[application.id] = can? :update, application
      @can_edit_app[application.id] = can? :edit, application
    end
    @can_create_app = can? :create, App.new
  end

  def fetch_requests(participated_in_by=true)
    # quick fix not no take into account "default" search string from client 'Search Requests'
    #should be changed on client side in this case send nothing
    if params[:q] && !params[:q].blank? && params[:q] != 'Search Requests'
      @requests = search_requests
    end

    get_data(participated_in_by, preload_steps = false) # preloading 100k steps takes around 60s. Hence it's set to false here.

    @requests = @requests.includes(:owner, :activity, :deployment_window_event).
        includes(plan_member: :plan)

    @requests = limit_to_last_90_days(@requests, @filter_or_search)

    @total_records = @requests.size
    paginate_requests

    RequestApplicationEnvironmentPreloader.new(@requests).preload
  end

  def search_requests
    @flag = 0
    @search_key = params[:q]
    if @search_key.include?('reqid')
      search_request_by_id
    elsif @search_key.include?('reqname')
      search_request_by_name
    else
      @filter_or_search = true
      current_user.requests(false).
          inner_apps_requests.
          name_like_or_id_like_or_notes_like_or_aasm_state_like_or_description_like_or_wiki_url_like(@search_key.downcase)
    end
  end

  def search_request_by_id
    q = @search_key.split(':')
    if q[1].blank?
      @flag = 1
      []
    else
      @filter_or_search = true
      Request.id_like(q[1])
    end
  end

  def search_request_by_name
    q = @search_key.split(':')
    if q[1].blank?
      @flag = 1
      []
    else
      @filter_or_search = true
      Request.where("LOWER(requests.name) like '%#{q[1].downcase}%'")
    end
  end

  def request_dashboard_data
    RequestDashboardView.new(params, @filters, session, current_user).dashboard_data
  end

  def dashboard_data
    DashboardView.new(params, @filters, current_user).dashboard_data
  end

end
