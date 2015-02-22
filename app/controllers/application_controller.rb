################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require "dynamic_form"
require "context_root"
require "devise"
require "global_settings"

class ApplicationController < ActionController::Base

  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    access_denied!
  end

  helper :all
  helper_method :current_pagination_page, :current_user, :session_filter_var, :remove_temp_filters, :host_url,
                :activity_link, :options_from_model_association,
                :recent_activity_show, :recent_activity_pagination,
                :request_link, :request_sso_enabled?, :current_user_authenticated_via_rpm?, :log_automation_errors
  skip_before_filter :authenticate_user!, :only => [:login]
  before_filter :authenticate_user!, :set_time_zone, :set_common_view_variables, :clear_global_settings_cache,
                :sign_out_inactive_user

  # log the user activity for online user sensor
  append_before_filter :verify_user_login_status
  before_filter :put_current_user_into_model
  before_filter :check_encryption

  after_filter :format_response_for_ajax_file_uploads, :user_activity

  @@cache_clear_time = Time.now

  DISPLAY_COUNT = [
      MY_APPLICATION_LIMIT = 6
  ]

  rescue_from(Timeout::Error) do |exception|
    @result = 'The script has timed out.  You may want to reduce the output of your command by adding "| tail -n 50" after the command'
    render :template => 'capistrano_scripts/test_run'
  end

  def verify_user_login_status
    if current_user
      if current_user.first_time_login?
        current_user.update_column :first_time_login, false
        redirect_to new_security_question_path
      elsif current_user.is_reset_password?
        current_user.update_column :is_reset_password, false
        redirect_to change_password_users_path
      end
    end
  end

  def streamstep_filters
    @global_filters = [Request::SortScope, ActivityDeliverable::SortScope, 'assignee_id', 'group_id', 'automation_category', 'automation_type', 'render_as'].flatten
  end

  def session_filter_var
    "#{params[:controller]}_#{params[:action]}"
  end

  def session_scope_name(scope)
    session_filter_var + (scope.nil? ? '' : "_#{scope}")
  end

  def session_scope(scope = nil)
    scope_name = session_scope_name(scope)
    session[scope_name] = {} if session[scope_name].blank?
    session[scope_name]
  end

  def reset_filters_hash!
    (streamstep_filters + %w(outbound_requests inbound_requests)).each {
      |s| session[session_filter_var].delete_if {|key, _| key.to_s == s.to_s }
    }
  end

  def add_temp_filters(selected_filters, temp_filters)
    streamstep_filters.each do |k|
      filter_arr = selected_filters[k].blank? ? [] : selected_filters[k]
      if filter_arr.is_a? Array
        unless temp_filters[k].blank?
          selected_filters.merge!({k => (filter_arr << temp_filters[k]).uniq})
        end
      end
    end
    selected_filters
  end

  def remove_temp_filters(selected_filters, all_filters)
    @temp_filters = {}
    streamstep_filters.each do |k|
      filter_arr = selected_filters[k].blank? ? [] : selected_filters[k]
      unless all_filters[k].blank?
        if filter_arr && filter_arr.size > 1
          filter_arr = filter_arr - [all_filters[k]]
        else
          filter_arr = [all_filters[k]] - filter_arr
        end

        @temp_filters[k.to_s] = all_filters[k]
      end
      selected_filters.merge!({k => filter_arr.uniq.flatten}) if filter_arr.respond_to?(:uniq)
    end
    @temp_filters['temp_filter'] = true
    selected_filters.delete_if { |k, v|
      v.is_a?(Array) && @temp_filters && (v.uniq.blank? or (v.uniq == [@temp_filters[k.to_s]]))
    }
    selected_filters
  end

  def temp_filters
    temp_filters_hash = {}
    streamstep_filters.each do |k|
      temp_filters_hash[k.to_s] = params[k.to_s] unless params[k.to_s].nil_or_empty?
    end
    temp_filters_hash['for_dashboard'] = params['for_dashboard'] if params['for_dashboard'] or !params['for_dashboard'].nil_or_empty?
    temp_filters_hash['time_zone'] = Time.zone.name
    temp_filters_hash
  end

  def activity_link(activity)
    "<a href='activities/#{activity}'>#{activity}</a>"
  end

  def request_link(request_number)
    "<a href = 'requests/#{request_number}'>#{request_number}</a>"
  end

  def reformat_date_for_save(date_string)
    return if date_string.nil?
    month = "1"
    day = "1"
    year = "1900"
    #match = date_string.gsub("-","/").match(/(\d+)\/|\-(\d+)\/|\-(\d+)/)
    match = date_string.gsub("-", "/").split("/")
    month_numbers = {"Jan" => "1", "Feb" => "2", "Mar" => "3", "Apr" => "4", "May" => "5", "Jun" => "6",
                     "Jul" => "7", "Aug" => "8", "Sep" => "9", "Oct" => "10", "Nov" => "11", "Dec" => "12"}
    format_codes = GlobalSettings[:default_date_format].gsub("-", "/").gsub(" ", "/").split("/")
    format_codes.each_with_index do |fmt, idx|
      case fmt.downcase
        when '%m'
          month = match[idx]
        when '%d'
          day = match[idx]
        when '%y'
          year = match[idx]
        when '%b'
          month = month_numbers[match[idx]]
      end
    end
    "#{year}-#{month}-#{day}"
  end

  def reformat_dates_for_save(hsh)
    hsh.each do |prim_key, prim_val|
      #logger.info "SS__ #{prim_key} => #{prim_val.inspect} is a #{prim_val.class.to_s}"
      if prim_val.class == Hash || prim_val.class == HashWithIndifferentAccess
        #logger.info "SS__ In Hash"
        hsh[prim_key] = reformat_dates_for_save(prim_val)
      else
        if (prim_key[-5, 5] == "_date") || (prim_key[-3, 3] == ("_at"))
          new_date = prim_val.length < 2 ? "" : reformat_date_for_save(prim_val)
          hsh[prim_key] = new_date
        end
      end
    end
    hsh
  end

  protected

  # because plans are so interconnected with other information, we get a 25% plus performance
  # gain when we include commonly accessed tables with the single plan grab
  def find_plan(my_id = nil)
    my_id ||= params[:plan_id] || params[:id]
    if my_id.to_i > 0
      begin
        @plan = Plan.preloaded_with_associations.find(my_id)
      rescue
        flash[:notice] = "Invalid plan id or plan not found."
        nil
      end
    end
  end

  def set_plan_tab_id
    @tab_id = params[:tab_id].present? ? params[:tab_id] : 1
  end

  def host_url
    "http://#{(request.port ? request.host_with_port : request.host)}"
  end

  def set_time_zone
    tz_default = GlobalSettings[:timezone].nil? ? "Eastern Time (US & Canada)" : GlobalSettings[:timezone]
    unless current_user.nil?
      tz_default = current_user.time_zone unless current_user.time_zone.nil?
    end
    Time.zone = tz_default
    tz_default
  end

  def current_pagination_page
    (params[:page] && params[:page].to_i > 0) ? params[:page] : 1
  end

  def requires_resource_manager
    unless current_user.resource_manager? || current_user.admin?
      redirect_to root_path
      return false
    end
    true
  end

  def options_from_model_association(object, association, options = {})
    return '' unless object

    finder_options = options[:find]         || {}
    named_scopes   = options[:named_scope]  || []
    value_method   = options[:value_method] || :id
    text_method    = options[:text_method]  || :name
    selected       = options[:selected]
    include_blank  = options[:include_blank]

    if options[:apply_method].present? && !current_user.admin?
      associated_models_array = eval("object.#{options[:apply_method]}")
    else
      named_scopes = [named_scopes] unless named_scopes.is_a?(Array)
      association_chain = object.send(association)
      named_scopes.each do |scope|
        if scope.is_a?(Hash)
          scope.each do |scope_name, scope_args|
            scope_args = [scope_args] unless scope_args.is_a?(Array)

            association_chain = association_chain.send(scope_name, *scope_args)
          end
        else
          association_chain = association_chain.send(scope)
        end
      end
      associated_models_array = association_chain.find(:all, finder_options)
    end
    options = ApplicationController.helpers.options_from_collection_for_select(associated_models_array, value_method, text_method, selected)
    options = "<option value=''>Select</option>\n" + options if include_blank
    options
  end

  def opt_group_options!(options, object, css_class)
    options_wrapped = "<optgroup id='#{object.id}' class='#{css_class}' label='#{object.name}' >" if params[:optgroup]
    options_wrapped += options
    options_wrapped += "</optgroup>" if params[:optgroup]

    options_wrapped
  end

  def find_application
    @app = App.find(params[:app_id])
  end

  def dashboard_setup
    @show_all = params[:show_all]
    @page_path = params[:show_all] ? request_dashboard_path : root_path
    @requests = if user_signed_in?
                  current_user.requests(@show_all).exclude_templates
                else
                  Request.extant.exclude_templates
                end
  end

  def get_data(participated_in_by=true, include_steps=true)
    @params = params
    session[session_filter_var] ||= HashWithIndifferentAccess.new
    unless params[:filters].nil_or_empty?
      sanitized_params = params[:filters]
      sanitized_params.each { |k, v| sanitized_params[k] = ERB::Util.html_escape(v) if v.is_a?(String) }
      session[session_filter_var].replace(sanitized_params)
    end
    reset_filters_hash! if params[:clear_filter]
    @filters = session[session_filter_var]
    unless @filters[:aasm_state].present? && @filters[:aasm_state].include?("deleted")
      @requests = @requests.functional
    end

    if user_signed_in? && !can?(:view_created_requests_list, Request.new)
      @requests = @requests.in_progress unless params[:request_ids].present? # Skipped when user is viewing Recently Updated Requests page
    end

    @beginning_of_calendar = params[:beginning_of_calendar]
    @end_of_calendar = params[:end_of_calendar]

    start_date = Date.generate_from(params[:beginning_of_calendar]) if params[:beginning_of_calendar].present?
    end_date = Date.generate_from(params[:end_of_calendar]) if params[:end_of_calendar].present?

    @requests_without_filters = @requests

    unless @filters.empty?
      if params[:filters][:inbound_requests].present?
        @requests = current_user.inbound_requests(@requests_without_filters)
        @filter_or_search = true
      end

      if params[:filters][:outbound_requests].present?
        @requests = current_user.outbound_requests(@requests_without_filters)
        @filter_or_search = true
      end

      filtered_requests = @requests.filtered(@filters, participated_in_by)
      @filter_or_search = true if @requests != filtered_requests
      @requests = filtered_requests

      if @filters[:sort_scope].present?

        # Rajesh Jangam: 10/12/2012
        # Fix for defect DE72568 - WS: Sorting Not Working for Steps Column on Requests Page
        # If the aggregation with select is used along with a query, the adapter gets confused and fails.
        # This happens on all databases. So this is a crude workaround
        #if @filters[:sort_scope] == "executable_step_count" #&& params[:q].present?
        #  @requests = Request.where(:id => @requests.collect {|r| r.id}).sorted_by(@filters[:sort_scope], @filters[:sort_direction] == 'asc')
        #else
        #  @requests = @requests.sorted_by(@filters[:sort_scope], @filters[:sort_direction] == 'asc')
        #end

        if @filters[:sort_direction].blank? && @filters[:sort_scope].eql?('id')
          @filters[:sort_direction] = current_user.list_order
        end

        @requests = @requests.sorted_by(@filters[:sort_scope], @filters[:sort_direction] == 'asc')

        # Rajesh Jangam: 10/12/2012
        # Fix for defect DE72568 - WS: Sorting Not Working for Steps Column on Requests Page
        # This is a MSSQL Adapter defect where it does not handle cascaded scopes with select and aggregation properly
        # This is MSSQL Specific. An Inspect kind of changes how scopes are evaluated and fixes a problem
        if MsSQLAdapter
          @requests.inspect
        end
      end

    end
    unless @requests.count.zero? #|| Request.functional.count.zero?
      apply_date_range(start_date, end_date)
    end

    # Used in dashboard to show the appropriate amount of requests
    # TODO: This was commented out. Why? Uncommenting it for now;
    @total_outbound_request = current_user.outbound_request_ids(@requests).count
    @total_inbound_request = current_user.inbound_request_ids_new(@requests).count

    temp_total = @requests.size

    unless MsSQLAdapter
      @requests = @requests.includes(:executable_steps) if include_steps
      @requests = @requests.includes([:apps, :environment, :release])
    end

    @total_records = (temp_total.is_a?(Hash) ? @requests.length : temp_total) || 0
  end

  def my_data
    @my_applications = current_user.accessible_apps
    @my_environments = current_user.accessible_environments
    @my_servers = current_user.accessible_servers.active
  end

  def format_response_for_ajax_file_uploads
    # made to work with jquery-form and jquery-jaxy
    if request.content_type.to_s == 'multipart_form' && params[:_ajax_flag]
      response.body = "<table>#{response.body}</table>"
    end
  end

  def redirect_back_or(path)
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to path
  end

  def paginate_records(records, params, per_page=20, page_no=params[:page])
    records = records.blank? ? [] : records
    page_no = 1 if page_no.blank? || page_no == 0
    WillPaginate::Collection.create(page_no || 1, per_page) do |pager|
      pager.replace records[pager.offset, pager.per_page]
      unless pager.total_entries
        pager.total_entries = records.size
      end
    end
  end

  def show_validation_errors(item, options={})
    respond_to do |format|
      @div          = options.fetch(:div) { 'error_messages' }
      @scroll       = true
      @div_content  = render_to_string(:template => 'misc/error_messages_for', :layout => false, :locals => {:item => item})

      format.js { render :template => 'misc/update_div', :handlers => [:erb], :content_type => 'application/javascript' }
    end
  end

  #FIXME: Some xhr requests are getting javascript error code instead of the home page
  def ajax_redirect(redirect_url)
    respond_to do |format|
      @redirect_url = redirect_url
      format.js { render :template => 'misc/redirect', :handlers => [:erb], :content_type => 'application/javascript' }
    end
  end

  def show_error_messages(item)
    respond_to do |format|
      @div = 'errors'
      @div_content = render_to_string(:template => 'misc/error_messages_for', :locals => {:item => item})
      format.js { render :template => 'misc/update_div', :handlers => [:erb], :content_type => 'application/javascript' }
    end
  end

  def show_general_error_messages(message)
    respond_to do |format|
      @div = 'errors'
      @show_div = 'errorExplanation'
      @div_content = message
      format.js { render :template => 'misc/show_div_update_div', :handlers => [:erb], :content_type => 'application/javascript' }
    end
  end

  def alert_message(message)
    render :update do |page|
      page.alert(message)
    end
  end

  def my_applications
    @current_user_apps = current_user.accessible_apps
    @my_applications = paginate_records(@current_user_apps, params, MY_APPLICATION_LIMIT)
    @page_no = 1
  end

  def plan_release_details
    @instance_template_type = params[:instance_template_type].blank? ? "plan" : params[:instance_template_type]
    @filters = params[:filters]
    if @filters[:sort_scope].blank? || @filters[:sort_direction].blank?
      @grouped_members = @plan.members
                             .includes(:request)
                             .run_execution_order
                             .group_by(&:plan_stage_id)
    else
      @grouped_members = @plan.members
                             .includes(:request)
                             .sorted_by(@filters[:sort_scope], @filters[:sort_direction] == 'asc')
                             .group_by(&:plan_stage_id)
    end
    @default_stage = PlanStage.default_stage
    @plan_stages = @plan.stages.includes(:environment_type, requests: [:plan_member, :owner, :release, :apps, :environment])
    @plan_stage_dates = @plan.stage_dates.group_by(&:plan_stage_id)
  end

  def access_denied!
    render nothing: true if params[:blank_on_deny] and return
    add_access_denied_flash_message
    request.xhr? ? ajax_redirect(MainTabs.root_path(current_user)) : redirect_to(MainTabs.root_path(current_user), flash: flash) and return
  end

  def can_perform_all_action_on_request
    @request ||= Request.find_by_number(params[:request_id] || params[:id])
    unless can?(:edit, @request)
      unless request.get?
        redirect_url = requests_path(@request)
        conditional_redirect(@request)
        flash[:notice] = "Access Denied! You do not have permissions to perform action on #{@request.name} request"
      end
    end
  end

  def conditional_redirect(redirect_url)
    request.xhr? ? ajax_redirect(redirect_url) : redirect_to(redirect_url)
  end

  def put_current_user_into_model
    if current_user
      User.current_user = current_user
      current_user.authenticated_in_rpm_db = (session[:auth_method] && session[:auth_method] == "Login")
    end
  end

  def current_user_authenticated_via_rpm?
    (session[:auth_method] && session[:auth_method] == "Login") || (current_user.root?)
  end

  def request_sso_enabled?
    session[:sso_enabled] = true if request.headers.has_key?("REMOTE_USER") && request.headers["REMOTE_USER"].present?
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      format.xml { head :not_found }
      format.any { head :not_found }
    end
  end

  def log_automation_errors(step, err, external_script_output)
    automation_error = JobRun.new
    automation_error.job_type = "Resource Automation"
    automation_error.step_id = step.try(:id) if step
    automation_error.started_at = Time.now
    automation_error.finished_at = Time.now
    automation_error.status = "Error"
    automation_error.stderr = err.message + err.backtrace.join("\n")
    automation_error.stdout = external_script_output.inspect # .try(:flatten_hashes) throwing errors!
    automation_error.user_id = User.current_user.try(:id)
    automation_error.save
  end

  private

  # update the time stamp on the current user if logged in to provide an easy activity sensor
  def user_activity
    current_user.touch(:last_response_at) if signed_in?
  end

  def signed_in?
    !current_user.blank?
  end

  # Overwriting the sign_out redirect path method
  def sign_out_and_redirect(resource_or_scope)
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    sign_out(scope)
    request.headers.has_key?("REMOTE_USER") ? (render :template => "sessions/destroy") : (redirect_to after_sign_out_path_for(scope))
  end

  # Attempts to authenticate the given scope by running authentication hooks,
  # but does not redirect in case of failures.
  # Overwriting for LDAP Authentication
  def authenticate(scope, authentication = "basic")
    @user = User.find_by_login(params[scope]["login"])
    if authentication == "ldap" && !user_is_root?
      User.ldap_authentication(params[scope]["login"], params[scope]["password"])
    else
      warden.authenticate(:scope => scope)
    end
  end

  # this common filter redirects if an api_token is present and not_valid
  def validate_api_filter
    if params[:token].nil?
      token = params[params.keys.reject { |k| [:action, :controller].include?(k) }.first][:token]
      unless token.nil?
        params[:token] = token
        params[params.keys.reject { |k| [:action, :controller].include?(k) }.first].delete(:token)
      end
    end
    @user = User.api_key_authentication(params[:token]) if params[:token]
    unless @user
      render :xml => "<xml><error><response>Invalid API Key</response></error></xml>", :status => :forbidden
      false
    end
  end

  # sets a variable for the instance name to improve performance
  # and simplify view rendering
  def set_common_view_variables
    @instance_name = (GlobalSettings[:company_name].nil? ? '' : 'Instance: '+GlobalSettings[:company_name])
    @user_name = current_user.try(:name) || ''
  end

  def clear_global_settings_cache
    unless request.xhr?
      current_time = Time.now
      if current_time - @@cache_clear_time > 300
        GlobalSettings.clear_local_instance
        @@cache_clear_time = current_time
      end
    end
  end

  def sign_out_inactive_user
    if current_user && !current_user.active?
      sign_out_all_scopes
      redirect_to login_path and return
    end
  end

  def check_encryption
    return unless params.has_key? :encrypted
    params[:encrypted].map { |k, _| GibberishHelper.decrypt_value(k, params) }
  end

  def add_access_denied_flash_message
    flash[:error] ||= ''
    flash[:error] << I18n.t(:'activerecord.errors.no_access_to_view_page')
  end

  # TODO this is quick fix for tests redefine ability during request
  # should be fixed to be not depend on env type
  class_eval do
    def current_ability
      @current_ability ||= Ability.new(current_user)
    end
  end if ENV["RAILS_ENV"] != "test"

  def user_is_root?
    @user.present? && @user.root?
  end

  def apply_date_range(start_date, end_date)
    if start_date.present? or end_date.present?
      if @split_date_by # @split_date_by is used only in CalendarsController#draw_calendar
        if start_date && !start_date.is_a?(Date)
          start_date = start_date.gsub('-', '/')
        end
        if end_date && !end_date.is_a?(Date)
          end_date = end_date.gsub('-', '/')
        end
      end
      if @filters[:ignore_month].blank?
        @requests = @requests.between_dates(start_date, end_date)
        @filter_or_search = true
      end
    end
  end

end
