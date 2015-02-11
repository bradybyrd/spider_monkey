################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class RequestsController < ApplicationController

  include TicketsHelper
  include DeploymentWindowSeriesHelper

  before_filter :load_request, :only => [ :edit,
                                          :update,
                                          :show
                                        ]
  before_filter :ensure_request_loaded, only: :update_state
  before_filter :set_package_template_and_env_ids, :only => :create_from_template
  before_filter :does_have_environments?, :only => :component_versions

  skip_before_filter :verify_authenticity_token, :only => :update_state


  before_filter :find_request, only: [:new_clone, :create_clone]

  include ApplicationHelper

  rescue_from(AASM::InvalidTransition) { |_| redirect_to request_path(params[:id]) }
  rescue_from CanCan::AccessDenied, with: :unauthorized, only: [ :edit ]

  cache_sweeper :request_sweeper, :steps_sweeper

  def index
    redirect_to request_dashboard_path(:q => params[:q])
  end

  def application_environment_options
    app_ids = params[:request][:app_ids] || params[:app_ids] || params[:request][:app_id] || params[:app_id]
    app_ids = [app_ids].flatten.reject{|s| s.blank? || s.empty?}
    if app_ids.present?
      @apps = App.where(id: app_ids).order('apps.name asc')
      render partial: 'application_environment_options'
    else
      render nothing: true
    end
  end

  def application_process_options
    app_ids = params[:request][:app_ids] || params[:app_ids] || params[:request][:app_id] || params[:app_id]
    app_ids = [app_ids].flatten.reject{|s| s.blank? || s.empty?}
    if app_ids.present?
      options = ''
      App.where(id: app_ids).order('apps.name asc').each do |app|
        options += "<optgroup id='#{app.id}' class='app' label='#{app.name}' >" if params[:optgroup]
        options += options_from_model_association(app, :business_processes,:scope => :unarchived)
        options += '</optgroup>' if params[:optgroup]
      end
      render text: options
    else
      render nothing: true
    end
  end

  def deployment_window_options
    params[:environment_id] = params[:environment_ids] if params[:environment_ids].present?
    options = available_for_request_from_params(params)
    options = options.paginate(:page => params[:page], :per_page => params[:page_limit])

    render :json => {
      more: (params[:page].to_i < options.total_pages),
      results: grouped_deployment_window_options(options)
    }
  end

  def deployment_window_next
    if params[:event_id].empty?
      next_event = available_for_request_from_params(params).first
    else
      event = DeploymentWindow::Event.find_by_id(params[:event_id])
      next_event = event.next_available_by_estimate(params[:request_estimate].to_i)
    end

    if next_event
      render :json => {
        id: next_event.id,
        text: deployment_window_event_option_text(next_event, true),
        start: next_event.start_at.strftime("%m/%d/%Y %r") # TODO: carry about date format change
      }
    else
      render :nothing => true
    end
  end

  def deployment_window_warning
    @type = 'deployment_window'
    if params[:event_id].present?
      event = DeploymentWindow::Event.find_by_id(params[:event_id])
      @warning = event.series.warning_state if event.series.warning_state?
    end
    render partial: "object_state/state_usage_warning"
  end

  def status
    if request.post?
      render :json => { :payload => Interrogator.new(params[:command]).respond }
    end
  end

  def set_unset_auto_refresh
    session[:request_auto_refresh] ||= []
    if params[:auto_refresh] && params[:auto_refresh] == "1"
      session[:request_auto_refresh] |= [params[:id]]
    else
      session[:request_auto_refresh].delete(params[:id])
    end
    render :text => session[:request_auto_refresh].include?(params[:id]) ? "true" : "false"
  end

  def get_status
    @request = find_request
    @request.should_finish?
    render :text => "#{@request.aasm.current_state}-#{@request.last_activity_by}-#{@request.last_activity_at.to_s}"
  end

  def needs_update
    last_check = session["last_update_check"]
    unless last_check.nil?
      @request = find_request
      #logger.info "SS__ Update Check: #{params.inspect}\n last act: #{@request.last_activity_at}\n#{session.inspect}"
      if last_check < @request.last_activity_at && @request.last_activity_by != current_user.id
        render :text => "#{@request.aasm.current_state}-#{@request.last_activity_by}-#{@request.last_activity_at.to_s}"
      else
        render :text => "false"
      end
    else
      render :text => "false"
    end
    session["last_update_check"] = Time.now
  end

  def collapse_header
    request = find_request
    render :partial => 'requests/collapsed_header', :locals => { :request => request }
  end

  def expand_header
    edit_without_authorization
    render :partial => 'requests/expanded_header', :locals => { :request => @request, :business_processes => @business_processes,
                                                                :apps => @apps, :human_date_format => @human_date_format }
  end

  def show
    authorize! :inspect, @request
    authorize_created_request! @request
    if request.xhr?
      render :partial => 'requests/request_name_tab'
    else
      InstalledComponent.without_finding_server_ids do
        edit_without_authorization
      end
      respond_to do |format|
        format.html {
          if params[:export]
            render :template => "requests/request_pdf",
                   :handlers => [:erb],
                   :formats => [:html],
                   :layout => "request",
                   :disable_internal_links => true,
                   :disable_external_links => true ,
                   :show_as_html => true
          else
            render :template => 'requests/edit'
          end
        }
        format.xml {
          authorize! :export_as_xml, @request
        }
        format.pdf do
          authorize! :export_as_pdf, @request
          render :pdf => "Release_Notes_#{@request.number}",
                 :template => "requests/request_pdf",
                 :handlers => [:erb],
                 :formats => [:html],
                 :layout => "request",
                 :disable_internal_links => true,
                 :disable_external_links => false ,
                 :show_as_html => params[:export] ? true : false
        end
      end
    end
  end

  def new
    @request ||= Request.new(:owner => current_user, :requestor => current_user)
    prepare_plan_data(params)
    @package_contents = PackageContent.unarchived.order("LOWER(name) asc")
    @request.activity_id = params[:activity_id] if params[:activity_id]
    @request.app_id = params[:activity_app_id] if params[:activity_app_id]

    # build an upload for the new record to show an upload form by default
    @request.uploads.build
    if @request.notes.blank?
      @request.notes.build
      @request.notes.first.user = current_user
    end

    @human_date_format = GlobalSettings.human_date_format
  end

  def load_request_steps
    @request = find_request
    @step_headers = @request.request_view_step_headers
    @steps_with_invalid_components = @request.steps_with_invalid_components
    @top_level_steps = @request.steps.top_level
  end

  def show_steps
    @request = Request.find_by_number(params[:id])
    RequestApplicationEnvironmentPreloader.new(@request).preload
    set_step_permissions(@request)

    respond_to do |format|
      format.js { render partial: 'show_steps', locals: show_steps_locals(@request) }
    end
  end

  def edit
    authorize! :inspect, @request
    authorize_created_request! @request
    edit_without_authorization(true)
  end

  def modify_details
    @request = find_request
    authorize! :edit, @request
    @human_date_format = GlobalSettings.human_date_format
    prepare_plan_data(params)
    @apps = App.active.with_installed_components.name_order
    @business_processes = BusinessProcess.unarchived.all(:order => 'name')
    render :layout => false
  end

  def notification_options
    @request = find_request
    authorize! :change_notification_options, @request
    @users = @request.available_users
    @groups = Group.active

    render :layout => false
  end

  def create
    return create_request_without_template if params[:from_promotion]

    environment_ids = MultipleEnvsRequestForm.parse_env_ids_from_params(params)
    if params[:request][:notes_attributes].present? && params[:request][:notes_attributes]['0'][:content].blank?
      params[:request][:notes_attributes] = {}
    end
    params[:request][:environment_id] = environment_ids.first if environment_ids.present?
    @request = current_user.owning_requests.new(reformat_dates_for_save(params[:request]))
    @request.aasm_state = 'created'
    @request.check_compliance_and_dw_errors(environment_ids)
    @request.check_permissions = true
    @request.should_time_stitch = true
    have_at_least_one_environment?(environment_ids)
    (params[:uploads] || []).each do |uploaded_data|
      @request.uploads.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
    end
    @request.environment_id = environment_ids.first if environment_ids.present?

    if @request.errors.blank? && @request.save
      (params[:request][:package_content_ids] || []).each do |package_content|
        @request.request_package_contents.create(:package_content_id => package_content)
      end
      # TODO: RJ: Rails 3: Log activity pending as plugin not working
      #current_user.log_activity(:context => "Request #{req_link} created") do
      @request.update_attribute(:updated_at, @request.updated_at)
      #end
      MultipleEnvsRequestForm.create_multiple_requests(@request, environment_ids, params)
      flash[:success] = I18n.t(:'request.notices.created')
      redirect_to edit_request_path(@request)
    else
      if environment_ids.present?
        @request.environment_ids = environment_ids
        @request.environment_id = nil
      end
      new
      render :new
    end
  end

  def create_request_without_template
    @request = current_user.owning_requests.new
    authorize! :create, @request
    @request.requestor_id, @request.owner_id = current_user.id, current_user.id
    @request.add_blank_steps_with_components = true
    @request_app_ids = params[:app_id]
    if params[:request]
      params[:request].delete_if { |k, v| v.blank? || k.eql?("app_ids") || k.include?("plan") }
      @request.attributes = params[:request].merge!({ :package_content_ids => params[:package_content_ids]})
    end
    @request.rescheduled = false # Rescheduled should be false for requests created from templates
    @request.save
    @request.update_attributes(:app_ids => @request_app_ids)
    @request.turn_off_steps # Turn OFF steps whose components are not selected
    @request.set_commit_version_of_steps
    redirect_to edit_request_path(@request)
  end

  def create_from_deployment_window
    @request = Request.new(params[:request])
    @request.requestor, @request.deployment_coordinator = current_user, current_user
    @request.scheduled_at = @request.deployment_window_event.start_at
  end

  def schedule_from_event
    authorize! :create, Request.new
    if params[:occurrence_id]
      occurrence = DeploymentWindow::Occurrence.find(params[:occurrence_id])
      @event = occurrence.events.by_environment(params[:env_id]).first
    else
      @event = DeploymentWindow::Event.find(params[:event_id])
    end

    series = DeploymentWindow::Series.find_by_name(@event.name.to_s)
    if series.warning_state?
      flash[:warning] = series.warning_state
    end
    @request = Request.new
    @request.deployment_window_event_id = @event.id
    @request.scheduled_at = @event.start_at
    prepare_plan_data(params)
    render :layout => false
  end

  def create_from_event
    authorize! :create, Request.new
    request_params = reformat_dates_for_save(params)
    request_params[:request][:should_time_stitch] = true
    request_params[:request][:rescheduled] = false

    if request_params[:request][:request_template_id].blank?
      @request = Request.new( request_params[:request] )
      @request.requestor = current_user
      @request.deployment_coordinator = current_user
      @request.owner = current_user
      @request.environment = @request.deployment_window_event.environment
    else
      request_template = RequestTemplate.find(request_params[:request][:request_template_id])
      @request = request_template.create_request_for(current_user, request_params)
      @request.name = request_params[:request][:name]
    end

    if RequestFromEventPolicy.new(@request).valid?
      @request.save
      render json: {request_path: request_path(@request)}
    else
      render json: {errors: @request.errors.full_messages}
    end
  end

  def update_notes
    @request = find_request
    authorize! :update_notes, @request
    authorize_created_request! @request
    if params[:update_notes_only].present?
      @request.notes.create(:user_id => current_user.id, :content => params[:request][:notes])
      respond_to do |format|
        format.js { render :template => 'requests/request_notes_update', :content_type => 'application/javascript'}
      end
    end
  end

  def update
    authorize_update! @request
    authorize_created_request! @request
    params[:request][:environment_id] ||= params[:selected_request_environment_id]
    @request.attributes = reformat_dates_for_save(params[:request])
    params[:request][:old_environment_id] = params[:old_environment_id]
    params[:request][:old_app_ids] = params[:old_app_ids]

    @request.should_time_stitch = true if params[:editing_details] == '1'

    @request.check_permissions = true

    @request.set_email_recipients(user_ids: params[:user_email_recipients], group_ids: params[:group_email_recipients])

    @request.uploads.destroy(@request.uploads.find(params[:upload_for_deletion])) if params[:upload_for_deletion]

    if @request.save
      @request.clear_assoc_objects({apps: params[:request][:app_ids] || params[:request][:app_id],
                                    package_contents: params[:request][:package_content_ids]}) unless params[:updating_notification_options]
      # If Request's Component version is changed,
      # then it will set all the versions to Blank as per the Clyde's comment in StoryID - 2739011 - (SN)
      # Commented as per the Duane's comment in Story ID:3095525
      #logger.info "SS__ UpdateReq: Saved change?: #{(params[:request][:old_environment_id]).to_s} params:#{params[:request].inspect}"
      if params[:request][:environment_id].present?
        unless (params[:request][:old_environment_id] == params[:request][:environment_id]) && (params[:request][:old_app_ids] == params[:request][:app_ids])
          old_environment = Environment.find(params[:request][:old_environment_id].to_i) rescue nil
          new_environment = Environment.find(params[:request][:environment_id].to_i) rescue nil
          old_name = old_environment.try(:name) || 'Unassigned'
          new_name = new_environment.try(:name) || 'Unassigned'
          ActivityLog.log_event(@request, @request.user, "environment changed from: #{old_name} to: #{new_name}")
          @steps = @request.steps.collect {|s| s.respond_to_app_env_change(params[:request]) }
        end
      else
        @request.steps.collect {|s| s.update_attributes(installed_component_id: '', component_id: '')}
      end

      flash[:success] = 'Request was successfully updated.'
      if request.xhr?
        ajax_redirect(request_path(@request))
      else
        redirect_to(@request)
      end
    else
      if request.xhr?
        show_validation_errors(:request)
      else
        flash[:failure] = 'Request was not updated.'
        edit_without_authorization
        render action: 'edit'
      end
    end
  end

  def destroy
    @request = find_request
    authorize! :delete, @request
    @request.destroy

    redirect_to request_dashboard_path
  end

  def reorder_steps
    authorize! :reorder_steps, Request.new
    begin
      @request = find_request
      @procedures = Procedure.unarchived.includes(:steps).with_app_id(@request.apps.map(&:id))
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Request you are trying to access either does not exist or has been deleted"
      request.xhr? ? ajax_redirect(root_path) : redirect_to(root_path) && return
    end
  end

  def update_state
    authorize_created_request! @request
    @request.state_changer = current_user

    case params[:transition].to_s
    when 'plan'
      authorize! :plan, @request
      @request.plan_it!
    when 'start'
      authorize! :start, @request
      @request.start_request!
      @request.steps.anytime_steps.where(should_execute: true).each(&:ready_for_work!)
    when 'hold'
      authorize! :hold, @request
      @request.put_on_hold!
    when 'problem'
      authorize! :put_in_problem, @request
      @request.update_attributes params[:request] if params[:request]
      @request.add_log_comments :problem, params[:note]  if params[:note]
      @request.problem_encountered!
    when 'resolve'
      authorize! :resolve, @request
      @request.update_attributes params[:request]  if params[:request]
      @request.add_log_comments :resolved, params[:note] if params[:note]
      @request.resolve!
    when 'cancel'
      authorize! :cancel, @request
      @request.update_attributes params[:request]  if params[:request]
      @request.add_log_comments :cancelled, params[:note] if params[:note]
      @request.resolve_step_servers_association!
      @request.cancel!
    when 'reopen'
      authorize! :reopen, @request
      @request.reopen!
    end

    # should just here because of `update_attributes` later would clear all the error messages
    flash[:error] = @request.errors.full_messages # unless transition_successful

    # Recent-Activity code
    @request.update_attributes(params[:request])

    flash[:error] += @request.errors.full_messages
    flash[:error] = flash[:error].compact.uniq.join('<br />').html_safe

    # The conditional assignments are resulting in { :error => nil }, which causes the flash div to be rendered with nothing in it.
    # Deleting the key prevents that.
    flash.delete(:error) if flash[:error].blank?

    edit_without_authorization(true)

    respond_to do |format|
      format.html { render template: 'requests/edit' }
    end

  end

  def notes_by_step
    @request = find_request

    note_groups = @request.executable_steps.map { |step| step.notes }

    render :partial => 'requests/notes_by_step', :locals => { :request => @request, :note_groups => note_groups }
  end

  def notes_by_user
    @request = find_request

    note_groups = @request.executable_steps.map { |step| step.notes }.flatten

    note_groups = note_groups.group_by { |note| note.user.name }

    render :partial => 'requests/notes_by_user', :locals => { :request => @request, :note_groups => note_groups }
  end

  def notes_by_time
    @request = find_request

    note_groups = @request.executable_steps.map { |step| step.notes }.flatten

    note_groups = note_groups.group_by { |note| note.updated_at.hour }

    render :partial => 'requests/notes_by_time', :locals => { :request => @request, :note_groups => note_groups }
  end

  def choose_environment_for_template
    @request_template = RequestTemplate.find(params[:request_template_id])
    @request = @request_template.request
    @plan = Plan.find_by_id(params[:plan_id]) if params[:plan_id].present?
    @plan_stage = PlanStage.find_by_id(params[:plan_stage_id]) if params[:plan_stage_id].present?
    prepare_plan_data(params)
    render :template => "requests/choose_environment_for_template", :layout => false
  end

  def create_from_template
    authorize! :create, Request.new

    params[:request] = {} unless params[:request]
    params[:request][:owner_id] = current_user.id  unless params[:request][:owner_id]
    environment_ids = MultipleEnvsRequestForm.parse_env_ids_from_params(params)

    if params[:request_template_id].blank?
      flash[:error] = 'Request Template was not specified'
      redirect_to :back
      return
    else
      begin
        @request_template = RequestTemplate.find(params[:request_template_id])
      rescue ActiveRecord::RecordNotFound
        flash[:error] = 'Request template requested was not found'
        redirect_to :back
        return
      end
      @request = current_user.owning_requests.new(reformat_dates_for_save(params[:request]))
      @request.requestor = current_user
      @request.aasm_state = 'created'
      @request.check_compliance_and_dw_errors(environment_ids)
      have_at_least_one_environment?(environment_ids)
      params[:request][:environment_id] = environment_ids.first if environment_ids.present?
      form_params = params[:request].dup
      @request = @request_template.instantiate_request(reformat_dates_for_save(params)) if @request.errors.blank?

      return if @request.errors.present? || (@request.invalid? && @request_template.request.apps.first.strict_plan_control)
      params[:request] = form_params
      MultipleEnvsRequestForm.instantiate_multiple_requests(@request_template, environment_ids, params)

      if @request_template.warning_state?
        flash[:warning] = @request_template.warning_state
      else
        flash[:success] = I18n.t(:'request.notices.created')
      end
      # Added in audit log for more user friendly description.
      ActivityLog.log_event(@request, current_user, 'Created request from template') if @request.valid?
    end
    respond_to do |format|
      format.js
      format.html { redirect_to request_path(@request) }
    end
  end

  def activity_by_time
    @request = find_request
    log_groups = @request.logs.first(10).group_by { |log| log.created_at.default_format }
    render :partial => 'requests/activity_by_time', :locals => { :request => @request, :log_groups => log_groups }
  end

  def activity_by_user
    @request = find_request
    log_groups = @request.logs.first(10).group_by { |log| log.user.name }
    render :partial => 'requests/activity_by_user', :locals => { :request => @request, :log_groups => log_groups }
  end

  def activity_by_step
    @request = find_request
    log_groups = @request.logs.first(10).group_by do |log|
      step = log.activity.match(/(Step\s\d+):/)

      step.nil? ? 'Request' : step[1]
    end

    log_groups.each do |group|
      unless group.first == 'Request'
        group[1].each do |log|
          log.activity.gsub!(/Step\s\d+:\s*/, '')
        end
      end
    end

    render partial: 'requests/activity_by_step', locals: {request: @request, log_groups: log_groups}
  end

  def add_category
    @request = find_request
    @categories = Category.unarchived.request.associated_event(params[:transition])

    @form_action = update_state_request_path(@request, params[:transition])

    render :layout => false
  end

  def add_message
    @request = find_request
    @transition = params[:transition]
    @message = @request.messages.build

    action = case @transition
    when 'start'
      'started'
    when 'hold'
      'put on hold'
    end

    @message.subject = "Request #{@request.number} has been #{action}."

    render :layout => false
  end

  def send_message
    #popup send message
    @request = find_request
    @transition = params[:transition]
    @message = @request.messages.build(params[:message])
    if @message.save
      begin
        flash[:success] = "Message Sent"
      rescue Exception => e
        logger.error("SS_ERROR NOTIFICATION: " + e.message + "\n" + e.backtrace.join("\n"))
        flash[:notice] = "Email notification failed"
      end
      render :text => update_state_request_path(@request, @transition)
    else
      render :text => "error"
    end
  end

  def add_procedure
    @request = find_request
    authorize! :add_procedure, @request
    @procedures = Procedure.unarchived.visible('procedures').with_app_id(@request.apps.pluck('apps.id'))
    @steps_count = {}
    @procedures.each do |procedure|
      @steps_count[procedure.id] = procedure.steps.count
    end
    render :layout => false
  end

  def add_new_procedure
    @request = find_request
    procedure = @request.steps.build
    procedure.procedure = true
    procedure.save!
  end

  def setup_schedule
    @activity = Activity.find(params[:activity_id])
    @request = @activity.requests.find_by_number(params[:id])

    authorize! :schedule_request, @request
    render :layout => false
  end

  def commit_schedule
    @activity = Activity.find(params[:activity_id])
    @request = @activity.requests.find_by_number(params[:id])

    authorize! :schedule_request, @request

    @request.setup_recurrance(params[:schedule])

    redirect_to @activity
  end

  def create_consolidated
    authorize! :create, Request.new
    authorize! :consolidate_requests, Request.new
    consolidated_request = Request.create_consolidated_request params[:request_ids], current_user
    if consolidated_request
      redirect_to edit_request_path(consolidated_request)
    else
      flash[:error] = 'You cannot Consolidate requests with Application that has strict plan control'
      redirect_back_or root_path
    end
  end

  def server_properties_for_step
    request             = find_request
    server_collection   = []
    installed_component = nil

    step = if !params[:step_id].nil? && (exists_step = Step.find(params[:step_id])) &&
               exists_step.installed_component &&
               exists_step.installed_component.try(:application_component).try(:component_id).to_s == params[:component_id].to_s

      exists_step
    else
      request.steps.build
    end

    step.component_id = params[:component_id]

    if step.installed_component
      server_collection       = step.installed_component.server_associations
      @server_association_ids = server_collection.pluck(:id) rescue []
      installed_component     = step.installed_component
    elsif !params[:component_id].empty?
      # find InstalledComponent manually
      # TODO: make this a single sql request
      app_id              = AppsRequest.find_by_request_id(request.id).app_id
      env_id              = request.environment.id
      comp_id             = params[:component_id]
      installed_component = InstalledComponent.find_by_app_comp_env(app_id, comp_id, env_id)

      server_collection   = installed_component.server_associations
    end

    # available servers to choose + chosen server(i.e. from another components)
    server_collection += step.targeted_servers
    server_collection = (step.complete? || step.request.already_started?) ? step.targeted_servers : server_collection.uniq

    render partial: 'steps/server_properties',
           locals: {step: step,
                    request: request,
                    server_collection: server_collection,
                    installed_component: installed_component}
      end

  def component_versions
    @request ||= find_request
    authorize! :edit_component_versions, @request

    if request.post?
      if params[:new_version]
        params[:new_version].each do |key, value|     # 'key' is step.id AND 'value' is step.component_version
          version_id = value.to_i if GlobalSettings.limit_versions? && value.to_i > 0
          unless value.eql?('') && version_id.nil?
            step = Step.find(key)
            #@steps = @request.steps.component_versions(step.component_id).collect {|s| s.update_attribute(:component_version, value) }
            @request.steps.component_versions(step.component_id).each do |s|
              version_name = version_id.nil? ? value : VersionTag.unarchived.find(version_id).try(:name)
              if GlobalSettings.limit_versions? && !version_id.nil?
                s.update_attributes({component_version: version_name, version_tag_id: version_id})
              else
                s.update_attribute(:component_version, version_name) # unless s.own_version  # update iff 'own_version' is not set.
              end
            end
          end
        end
      end
      redirect_to request_path(@request)
    else
      @steps = []
      @request.steps.group_by_components.each do |step|
        @steps << Step.find(step.id)
      end
      render layout: false
    end
  end

  # Process report tab
  def summary
    @request = find_request
    authorize! :view_coordination_summary, @request
    edit_without_authorization
  end

  # Activity report tab
  def activity_summary
    @request = find_request
    authorize! :view_activity_summary, @request
    @report_view = true
    @note_groups = @request.ordered_steps(true).map { |s| [s,s.notes] }
    index = @request.logs.find_index{|log|  log.activity=='Planned' }
    if index.nil?
      @log_groups_design = @request.logs.group_by { |log| log.created_at.default_format }
      @log_groups = Hash.new
    else
      @log_groups_design = (@request.logs.last(@request.logs.length - (index+1))).group_by { |log| log.created_at.default_format }
      @log_groups =  (@request.logs.first(index+1)).group_by { |log| log.created_at.default_format }
    end
    if request.xhr?
      render :layout => false
    else
      respond_to do |format|
        format.html {
          if params[:export]
            render :pdf => "Coordination_Summary_#{@request.number}", :template => "requests/summary_pdf",  :handlers => [:erb], :formats => [:html],
              :layout => "request", :show_as_html => true
          end
        }
        format.pdf do
          render :pdf => "Release_Notes_#{@request.number}", :template => "requests/activity_summary_pdf", :handlers => [:erb], :formats => [:html],
            :layout => "request", :show_as_html =>  params[:export] ? true : false
        end
      end
    end
  end

  # Property report tab
  def property_summary
    @request = find_request
    authorize! :view_property_summary, @request
    @report_view = true
    @property_maps = @request.property_summary_maps
    @note_groups = @request.ordered_steps(true).map { |s| [s,s.notes] }
    @log_groups = @request.logs.group_by { |log| log.created_at.default_format }
    if request.xhr?
      render :layout => false
    else
      respond_to do |format|
        format.html
      end
    end
  end

  # To display the environment version for each component while changing the 'Proposed Version' - SN
  def env_visibility
    @request ||= find_request
    @steps = @request.steps.group_by_components

    respond_to do | format |
      @env_id = params[:env_id]
      @checked_status = params[:checked_status]
      format.js { render template: 'requests/env_visibility', handlers: [:erb], content_type: 'application/javascript' }
    end
  end

  def request_modification
  end

  def bulk_destroy
    authorize! :delete, Request.new
    if request.delete?
      request_ids = params[:request_ids]
      requests = Request.find(request_ids)
      requests.each do |request|
        if can? :delete, request
          ActivityLog.log_event(request, current_user, "Delete request #{request.name}")
          request.destroy
        end
      end
      render :nothing => true
    else
      @request_dashboard = RequestDashboardView.new(params, @filters, session, current_user).dashboard_data
      @request_dashboard[:page_path] = bulk_destroy_path

      if request.xhr?
        render partial: 'requests/bulk_delete_requests'
      end
    end
  end

  def modify_request
    @request = Request.in_assigned_apps_of(current_user).find_by_number(params[:request_id]) rescue ''
    if @request.blank?
      render :text => "Invalid request id."
    elsif  @request.aasm_state == "deleted"
      render :text => "Request id has been deleted."
    else
      @human_date_format = GlobalSettings.human_date_format

      prepare_plan_data(params)

      @apps = App.active.with_installed_components.name_order
      @business_processes = BusinessProcess.unarchived.all(:order => 'name')
      render :template =>'requests/modify_details', :layout => false
    end
  end

  def apply_template
    @request = find_request
    authorize! :apply_template, @request
    prepare_plan_data(params)
    redirect_to request_path(@request) and return unless @request.created?
  end

  def package_template_items_for_steps
    package_template = PackageTemplate.find(params[:package_template_id])
    render :partial => "steps/app_package_template_items", :locals => { :package_template => package_template }
  end

  def template_item_properties
    template_item = PackageTemplateItem.find(params[:template_item_id])
    step = Step.find(params[:step_id]) rescue nil
    application_component = template_item.component_template.application_component rescue nil
    property_values = application_component.nil? ? nil : application_component.property_values.in_groups_of(2, nil)
    render :partial => "steps/package_template_item_properties", :locals => { :application_component => application_component,
                                                                              :property_values => property_values,
                                                                              :template_item => template_item,
                                                                              :step => step
                                                                              }
  end

  # Change request status from Plan screen
  def change_status
    @request = find_request
    @request.get_plan_member_status   #update_request_status_from_plan
    redirect_to plans_path + "#lifecyle#{params[:plan_id]}"
  end

  def update_request_info
    @request = Request.find(params[:id])
  end

  def service_now_servers
    request = Request.find(params[:id])
    step = request.steps.build
    step.component_id = params[:component_id]
    servers = if params[:klass] == "ProjectServer"
      ProjectServer.find(params[:object_id])
    else
      ChangeRequest.find(params[:object_id]).project_server
    end.service_now_servers
    server_names = step.server_association_names
    server_names = if server_names.blank?
      []
    else
      servers.name_equals(server_names)
    end
    render :text => ApplicationController.helpers.options_from_collection_for_select(server_names, :sys_id, :name, nil)
  end

  def deleted_requests
    @deleted_requests = Request.deleted.all(:order => 'requests.id DESC')
    @request_list_preferences = current_user.request_list_preferences.active
    if request.xhr?
      render :partial => "requests/custom_list", :locals => {:requests => @deleted_requests}
    end
  end

  def paste_steps
    @request = find_request
    authorize! :import_steps, @request

    if request.post? && @request
      # logger.info("SS__ Paste #{params[:paste_data].length}, #{params[:paste_data].inspect}")

      if params[:paste_data].length > 10
        result = @request.import_steps(params[:paste_data])
        flash[:error] = result unless result.include?("Success")
        flash[:success] = result if result.include?("Success")
      end
      redirect_to request_path(@request)
    else
      flash[:error] = "Bad request or post data"
      render :layout => false
    end
  end

  def export_xml
    @request = find_request
    authorize! :export_as_xml, @request
    if @request
      begin
        if params[:send_inline_xml].present?
          send_data @request.as_export_xml, :type => 'text/xml', :filename => "#{@request.number}.xml"
        else
          render :xml => xml
        end
      rescue Exception => e
        flash[:error] = "Request export cannot be created"
        logger.info "SS__ Export Error: #{e.message}\n#{e.backtrace}"
        redirect_to request_path(@request)
      end
    end

  end

  def import_xml
    authorize! :import, Request.new
    render :layout => false
    #render :template => "requests/add_xml"
  end

  def all_notes_for_request
    request = find_request
    render :partial => 'requests/all_notes_for_request', :locals => { :request => request }
  end

  def import
    authorize! :import, Request.new
    if params[:request].nil?
      flash[:error] = "Please select the file to import."
    else
      if params[:request].content_type == "text/xml"
        begin
          request_number = Request.import(params[:request].read, current_user)
          if request_number
            flash[:success] = "Request #{request_number} created, see description for details"
          else
            flash[:error] = "Request is not imported"
          end
        rescue ArgumentError => e
          flash[:error] = e.message
        end
      else
        flash[:error] = "Imported file should be in XML format"
      end
    end
    redirect_to request_dashboard_path
  end

  def new_clone
    authorize! :clone, @request
    @human_date_format = GlobalSettings.human_date_format

    if @request.request_template && @request.request_template.warning_state?
      flash[:warning] = @request.request_template.warning_state
    end

    prepare_plan_data(params)
    @apps = App.active.with_installed_components.name_order
    @business_processes = BusinessProcess.unarchived.all(:order => 'name')
    @cloned_request = Request.new
    render :template =>'requests/clone', :layout => false
  end

  def create_clone
    authorize! :create, @request
    params[:request] = reformat_dates_for_save(params[:request])
    @cloned_request = @request.clone_request_with_dependencies(params)
    if @cloned_request.valid?
      if @request.request_template && @request.request_template.warning_state?
        flash[:warning] = @request.request_template.warning_state
      else
        flash[:success] = 'Request successfully created'
      end
      request.xhr? ? ajax_redirect(request_path(@cloned_request)) : redirect_to(@cloned_request)
    else
      show_validation_errors(@cloned_request)
    end
  end

  def multi_environments
    return render :nothing => true if params[:app_id].blank? && params[:request_template_id].blank?

    @items = {}
    if params[:app_id].present?
      find_application
    else
      @app = RequestTemplate.find(params[:request_template_id]).request.apps.first
    end

    #items all - visible environments
    @items[:all] =
        if current_user.has_global_access?
          @app.environments.active
        else
          @app.environments_visible_to_user
        end

    #disabled_items - visible environments but user don`t have permissions to create request
    @items[:disabled_items] = current_user.get_disabled_environments(@app, @items[:all])

    @items[:selected_items] = []
    if @items[:all].present?
      render :partial => 'multi_environments'
    else
      render :nothing => true
    end
  end

protected

  def prepare_plan_data(passed_params = {})
    request_plan_data = RequestPlanData.new(@request, passed_params, current_user)

    @plan_member = request_plan_data.plan_member
    @available_plans_for_select = request_plan_data.available_plans_for_select
    @available_plan_stages_for_select = request_plan_data.available_plan_stages_for_select
    @stages_requestor_can_not_select = request_plan_data.stages_requestor_can_not_select
  end

  def ensure_request_loaded
    @request ||= Request.find_by_number(params[:request_id] || params[:id])
  end

  def does_have_environments?
    @request ||= find_request
    if @request.environment_id.blank?
      flash[:error] = "Environments are not associated with request" + (@request.request_template_id.blank? ? "" : " template")
      request.xhr? ? ajax_redirect(request_path(@request)): redirect_to(@request) && return
    end
  end

  def find_request
    @request = Request.extant.find_by_number(params[:id])
  end

  def set_package_template_and_env_ids
    if params[:request][:package_template_ids].present? && params[:request][:package_template_ids].first.include?(',')
      params[:request].merge!({:package_template_ids => params[:request][:package_template_ids].first.split?(',')})
    end
    params[:request][:environment_id] = params[:target_env] if params[:target_env].present?
  end

  def paginate_requests
    per_page = @filters[:per_page].blank? ? 20 : @filters[:per_page].to_i
    args_hash = {:page => params[:page], :per_page => per_page, :count => {:select => "distinct requests.id"}}
    args_hash.merge!({:order => "requests.id #{current_user.list_order}"}) unless @filters[:sort_scope].present?
    @requests = @requests.paginate(args_hash)
  end

private

  def grouped_deployment_window_options(options)
    rows = options.map do |row|
      {
        id: row.id,
        text: deployment_window_event_option_text(row),
        full_text: deployment_window_event_option_text(row, true),
        month: row.start_at.strftime("%B"),
        start: row.start_at.strftime("%m/%d/%Y %r")
      }
    end
    rows.group_by { |result| result[:month] }
    .map {|month, items| {text: month, children: items} }
  end

  def available_for_request_from_params(params)
    rows = DeploymentWindow::Event.allowing.not_archived.series_visible.active.by_environment(params[:environment_id])

    if params.has_key?(:q) && !params[:q].empty?
      rows = rows.by_name(params[:q])
    end

    time = params[:scheduled_at_date].empty? ? Time.now : schedule_time_from_params(params)
    rows = rows.finish_after(time)

    unless params[:estimate].empty?
      rows = rows.by_estimate(params[:estimate].to_i)
    end

    rows.ordered_by_start_finish
  end

  def schedule_time_from_params(params)
    scheduled_date = reformat_date_for_save(params[:scheduled_at_date])
    year, month, day = scheduled_date.split('-')
    hour = params[:scheduled_at_hour].empty? ? 12 : params[:scheduled_at_hour].to_i
    meridian = params[:scheduled_at_meridian].empty? ? 'AM' : params[:scheduled_at_meridian]
    if meridian == 'AM' && hour == 12
      hour = 0
    elsif meridian == 'PM' && hour != 12
      hour += 12
    end
    minute = params[:scheduled_at_minute].empty? ? 0 : params[:scheduled_at_minute]
    Time.zone.local(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i)
  end

  def load_request
    @request ||= find_request
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Request you are trying to access either does not exist or has been deleted"
    request.xhr? ? ajax_redirect(root_path) : redirect_to(root_path) && return
  end

  def unauthorized(exception = nil)
    flash[:notice] = I18n.t(:'activerecord.notices.no_permissions', action: 'access', model: 'the page you requested')
    request.xhr? ? ajax_redirect(root_path) : redirect_to(root_path) && return
  end

  def edit_without_authorization(limit_data = false)

    @note_groups = @request.ordered_steps(true).map { |s| [s, s.notes] } unless limit_data

    @request_logs = @request.logs.includes(:user).all
    @request_associated_users = {}

    User.where(id: @request_logs.collect { |l| l.user_id }.flatten.uniq).each do |u|
      @request_associated_users[u.id] = u.name
    end

    @log_groups = @request_logs.group_by { |log| log.created_at.default_format }
    @human_date_format = GlobalSettings.human_date_format

    unless limit_data
      @apps = App.active.with_installed_components.name_order
      @business_processes = BusinessProcess.unarchived.all(order: 'name')

      @users = @request.available_users
      @groups = @request.available_groups(@users.map(&:id))
      @steps_with_invalid_components = @request.steps_with_invalid_components

      @request_available_components = @request.available_components

      @unfolded_steps = Step.find_all_by_id((params[:unfolded_steps] || '').split(','))

      @package_contents = PackageContent.unarchived.in_order
    end

    @report_view = false

    unless @request.request_template_id.nil?
      @templates_sibling = RequestTemplate.template_variants(@request)
      @request_template = @request.request_template
    end
    @store_url = true

    # build plan_member if none exists so nested form works
    @request.build_plan_member if @request.plan_member.nil?

    # build an upload for the new record to show an upload form by default
    @request.uploads.build if @request.uploads.blank?

    if params[:action] == 'summary'
      if request.xhr?
        render layout: false
      else
        respond_to do |format|
          format.html {
            if params[:export]
              render template: 'requests/summary_pdf', handlers: [:erb], formats: [:html], layout: 'request', show_as_html: true
            end
          }
          format.pdf do
            render pdf: "Coordination_Summary_#{@request.number}", template: 'requests/summary_pdf', handlers: [:erb], formats: [:html],
                   layout: 'request', show_as_html: params[:export] ? true : false
          end
        end
      end
    end
  end

  def authorize_update!(request)
    raise CanCan::AccessDenied if !(can?(:edit, request) || can?(:apply_template, request) || can?(:change_notification_options, request) || can?(:edit_component_versions, request))
  end

  def authorize_created_request!(request)
    authorize! :view_created_requests_list, request if request.created?
  end

  def show_steps_locals(request)
    {
      request: request,
      step_headers: request.request_view_step_headers,
      steps_top_level: request.get_all_top_level_steps.all,
      steps_with_invalid_components: request.steps_with_invalid_components,
      step_preference_lists: current_user.step_list_preferences.active.all,
      available_package_ids: request.available_package_ids
    }
  end

  def set_step_permissions(request)
    @can_add_serial_procedure_step = can?(:add_serial_procedure_step, request)
    @can_remove_procedure = can?(:remove_procedure, request)
    @can_edit_procedure_execute_conditions = can?(:edit_procedure_execute_conditions, request)
    @can_run_step = can?(:run_step, request)
    @can_edit_step = can?(:edit_step, request)
    @can_reset_step = can?(:reset_steps, request)
    @can_delete_steps = can?(:delete_steps, request)
    @can_inspect_steps = can?(:inspect_steps, request)
    @can_turn_on_off_steps = can?(:turn_on_off_steps, request)
    @request_editable_by_user = request.editable_by?(current_user)
    @request_available_for_user = request.is_available_for?(current_user)
  end

  def have_at_least_one_environment?(environment_ids)
    if MultipleEnvsRequestForm.no_one_environment?(params[:request], environment_ids)
      @request.errors.add(:base, I18n.t(:'request.validations.at_least_one_env'))
    end
  end

end
