################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'csv'

class PlansController < ApplicationController
  include TicketsHelper

  before_filter :selectbox_data, :only => [:index, :show, :edit, :new, :update, :create, :filter ]
  skip_filter   :verify_authenticity_token, :only => [:ticket_summary_report]
  before_filter :read_only?, only: [:update, :edit]
  include ApplicationHelper


  cache_sweeper :plans_sweeper

  def index
    authorize! :view, :plans_tab

    # load the entire set and the working set
    @all_plans = Plan.entitled(current_user).includes(plan_template: :stages)
    @filters = params[:filters] || session[:session_filter_plan_var]
    unless params[:filters].nil_or_empty?
      session[:session_filter_plan_var] = params[:filters]
    end
    # check for conditions that lead to a full page reload of all plans
    reload = params[:clear_filter] == '1'
    # send filter, it will return functional plans if filters are nil
    unless reload
      @plans = Plan.filtered(session[:session_filter_plan_var], true, @all_plans)
    else
      @plans = @all_plans.without_deleted
    end

    # check for an additional keyword and add that onto any filters
    @keyword = params[:key]
    @plans = @plans.search_by_ci('plans.name', @keyword ) if @keyword.present?
    @plans = @plans.all.uniq
    # paginate and establish a maximum count of stages to draw the right number of columns
    @page = params[:page] || 1

    @plans = @plans.paginate(:page => params[:page], :per_page => 25)


    respond_to do |format|
      if @plans
        if request.xhr?
          format.html { render :partial => "plans/automated_plan",
              :locals => {:plans => @plans, :filters => @filters }
            }
        else
          format.html { render 'index' }
          format.xml  { render :xml => @plans }
        end
      else
        flash.now[:error] = "No Plan Found" if @plans.blank?
        format.html { render 'index',  :notice => "No plans found." }
        format.xml  { render :status => :not_found }
      end
    end
  end

  def filter
    index
  end

  def new
    @plan = Plan.new
    authorize! :create, @plan
  end

  def show
    @plan = find_plan
    authorize! :inspect, @plan

    if @plan.aasm_state.eql?('deleted')
      if request.xhr?
        flash[:notice] = "The plan you are trying to view is deleted."
        render js: "$('#plan_stages').hide(); window.location.pathname='#{root_path}'"
      else
        redirect_to root_path, notice: "The plan you are trying to view is deleted."
      end
    else
      @run = @plan.runs.find(params[:run_id].to_i) rescue nil if params[:run_id].to_i != 0
      @sel_requets = params[:sel_request] if params[:sel_request]
      # set the selected tab to plan tab
      @page_tab_selected = "#{@plan.name} - #{@plan.plan_template.template_type_label}".underscore
      #if we have a run, check its status, update its status, or just display it
      if @run
        #FIXME: aasm states are being sent here, probably an ajax and facebox workaround
        authorize! :inspect_run, @plan
        @aasm_event = params[:aasm_event]
        if @aasm_event && !@run.update_attributes(aasm_event: @aasm_event)
          flash.now[:error] = "Sorry. We could not update state of run to #{@aasm_event}."
        else
          #check its status which only does work if it is running
          @run.check_status
        end
      elsif params[:run_id].to_i != 0
        # show an error message if they tried to find a run by sending an id and failed
        flash.now[:error] = "Run not found for this plan."
      end

      respond_to do |format|
        if @plan
          # sets the grouped member and instance template type
          plan_release_details
          if request.xhr?
            format.html {
              render partial: "plans/stages",
                     locals: { plan: @plan,
                               grouped_members: @grouped_members,
                               default_stage: @default_stage,
                               plan_stages: @plan_stages }
            }
          else
            format.html
            format.xml  { render xml: @plan }
          end
        else
          format.html { redirect_to( plans_path, notice: "Plan #{params[:id] || params[:plan_id]} was not found.") }
          format.xml  { render xml: @lifecyle.errors, status: :not_found }
        end
      end
    end
  end

  def edit
    @plan_tab_value = params[:selected]
    @plan = find_plan
    authorize! :edit, @plan
    @plan_stage_dates = @plan.stage_dates.group_by(&:plan_stage_id)
    render :layout => false
  end

  # revised to push procedural code into relevant models and callbacks
  # and use standard respond to blocks in anticipation of rest support in the controller
  def create
    @plan = Plan.new(reformat_dates_for_save(params[:plan]))
    authorize! :create, @plan

    # warning or notice?
    if @plan.plan_template && @plan.plan_template.warning_state?
      flash[:warning] =  @plan.plan_template.warning_state
    else
      flash[:notice] = 'Plan was successfully created.'
    end
    respond_to do |format|
      if @plan.save
        format.html { redirect_to(@plan) }
        format.xml  { render :xml => @plan, :status => :created, :location => @plan }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @plan = find_plan
    authorize! :edit, @plan
    # BJB 11-30-10 Cast all into USDate for save
    lc_params = reformat_dates_for_save(params[:plan])

    respond_to do |format|
      if @plan.update_attributes(lc_params)
        flash[:notice] = 'Plan was successfully updated.'
        redirect_path = path_for_tab(params[:tab])

        params.each do |p|
          if p[0].start_with?("start_ead_")
            ead_id = (p[0].split("start_ead_"))[1]
            env_app_date = PlanEnvAppDate.find(ead_id)

            start_date = reformat_date_for_save(params["start_ead_#{ead_id}"].to_s)
            end_date = reformat_date_for_save(params["end_ead_#{ead_id}"].to_s)
            env_app_date.update_attribute("planned_start", start_date)
            env_app_date.update_attribute("planned_complete", end_date)
          end
        end

        if request.xhr?
          format.html { ajax_redirect(redirect_path) }
        else
          format.html { redirect_to redirect_path, :notice => "Plan was successfully updated." }
          format.xml  { head :ok }
        end
      else
        if request.xhr?
          format.html { show_validation_errors(:plan) }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    # TODO: Do we need this?
    @plan = find_plan
    @plan.destroy

    respond_to do |format|
      format.html { redirect_to(plans_path) }
      format.xml  { head :ok }
    end
  end

  def select_members
    @plan = find_plan
    @available_members = @plan.members.available_for(@plan)
    render :layout => false
  end

  def enroll_members
    @plan = find_plan
    @plan.update_attributes(params[:plan])
    redirect_to @plan
  end

  def promote_members
    plan = find_plan
    members = plan.members.find_all_by_id(params[:member_ids])
    members.each { |m| m.promote! }
    redirect_to plan
  end

  def demote_members
    plan = find_plan
    members = plan.members.find_all_by_id(params[:member_ids])
    members.each { |m| m.demote! }
    redirect_to plan
  end

  def update_members_statuses
    plan = find_plan
    plan.members.find_all_by_id(params[:member_ids]).each do |member|
      member.update_attributes(:plan_stage_status_id => params[:status_id])
    end
    redirect_to plan
  end

  def update_plan_templates_list
    @plan_templates = PlanTemplate.unarchived.find_all_by_template_type(params[:template_type])
  end

  def prepare_activity
    @plan = find_plan
    @stage = @plan.stages.find_by_id(params[:plan_stage_id])
    @request_template = @stage.request_template
    @request = Request.new(@stage.request_attributes)
    @environments = Environment.active.all(:order => 'name')
    @activity_categories = ActivityCategory.request_compatible
    @activities = Activity.request_compatible

    render :layout => false
  end

  # going to be deprecated
  def create_activity
    plan = find_plan

    if params[:activity_id].blank?
      activity = Activity.create!(params[:activity].merge(:user => current_user))
    else
      activity = Activity.find(params[:activity_id])
    end

    members = PlanMember.find_all_by_id(params[:member_ids])
    request_template = PlanStage.find_by_id(params[:plan_stage_id]).try(:request_template)

    members.each do |member|
     # member.add_to_activity(activity, request_template, params)
    end

    redirect_to plan
  end

  # Update Plan state and respective Requests.
  def update_state
    @plan = find_plan
    state = case params[:state].to_s
    when 'cancel'
      authorize! :cancel, @plan
      @plan.cancel!
      # @plan.requests.collect { |r| r.cancel! if ['created', 'planned', 'started', 'problem', 'hold'].include?(r.aasm_state) }
    when 'plan_it'
      authorize! :plan, @plan
      @plan.plan_it!
    when 'start'
      authorize! :start, @plan
      @plan.start!
    when 'lock'
      authorize! :lock, @plan
      @plan.lock!
    when 'unlock'
      authorize! :start, @plan
      @plan.start!
    when 'hold'
      authorize! :hold, @plan
      @plan.put_on_hold!
    when 'finish'
      authorize! :complete, @plan
      @plan.finish!
    when 'archived'
      authorize! :archive_unarchive, @plan
      @plan.archive!
    when 'delete'
      authorize! :delete, @plan
      @plan.delete!
    when 'reopen'
      authorize! :reopen, @plan
      @plan.reopen!
      # @plan.requests.collect { |r| r.soft_delete! if ['cancelled', 'complete'].include?(r.aasm_state) }
    end
   redirect_to (params[:state].to_s == 'delete' ? plans_path : plan_path(@plan))
  end

  def start_request
    @request = Request.find_by_number params[:id]
    # @request.plan_it!
    @request.start_request!
    render :nothing => true
  end

  def plan_stage_options
    unassigned = "<option value='0'>Unassigned</option>"
    if params[:plan_id].present?
      plan = Plan.find(params[:plan_id]) rescue nil
      if plan && plan.stages
        stage_options = [unassigned]
        new_options =  plan.stages.collect do |s|
          can?(:choose, s) || s.requestor_access ? "<option value='#{s.id}'>#{s.name}</option>" :
                                                   "<option value='#{s.id}' disabled='disabled'>#{s.name} - Restricted</option>"
        end
        render :text => (stage_options + new_options).join(" ")
      else
        render :text => '<option>Invalid plan.</option>'
      end
    else
      render :text => unassigned
    end
  end

  def applications
    plan = Plan.find(params[:id])
    render :text => options_from_model_association(plan, :applications)
  end

  def move_requests
    @plan = find_plan
    authorize! :move_requests, @plan
    if @plan
      if @plan.archived?
        flash[:notice] = "No stage selected for move."
        render text: 'Plan is archived.'
        return
      end
      if request.post?
        stage = @plan.stages.find(params[:stage_id]) rescue nil
        if stage
          stage.add_requests!(params[:request_ids])
        else
          flash[:notice] = "No stage selected for move."
        end
        redirect_to plan_path(@plan)
      else
        submitted_ids = params[:request_ids]
        requests = Request.find(submitted_ids) rescue []
        @request_ids = requests.select { |r| r.plan_member.run_id.blank? }.map(&:id)
        @run_requests_purged = submitted_ids.length - @request_ids.length
        render :layout => false
      end
    end
  end

  # refactored to record the index of member requests
  # within the stage list.
  # TODO: Should be an update rest call to plan member with extra parameters
  def reorder
    # get the member
    member_to_insert = PlanMember.find(params[:member_to_insert_id]) rescue nil
    unless member_to_insert.nil?
      new_stage_id = params[:new_stage_id].to_i
      member_to_target_id = params[:member_to_target_id].to_i
      # before doing anything, we can't allow run members to be dragged out of the stage
      if member_to_insert.run.blank? || new_stage_id == member_to_insert.plan_stage_id
        # to make a move, we always need a member_to_insert, and
        # we need either a member_to_target OR a stage_id, otherwise ignore
        if new_stage_id + member_to_target_id > 0
          # tell the class to reorder the work based on this information, returns success boolean
          unless member_to_insert.move_to_member_or_stage(member_to_target_id, new_stage_id.to_i)
            flash[:notice] = "Reorder of requests failed."
          end
        else
          member_to_insert.update_attribute(:plan_stage_id, 0)
          flash[:notice] = "Request moved to unassigned stage."
        end
      else
        flash[:notice] = "Requests assigned to runs cannot be dragged out of stage."
      end
    else
      flash[:notice] = "Invalid plan member dragged and dropped."
    end

    @plan = find_plan
    plan_release_details
    @run_id = params[:run_id].to_i
    @run = Run.find(@run_id) rescue nil
    # rewrite the stages in one shot after reassignment
    render :partial => "plans/stages", :locals => {
            :plan => @plan, :grouped_members => @grouped_members,
            :default_stage => @default_stage, :plan_stages => @plan_stages, :object => flash[:notice], :run => @run}

    #FIXME: flash messages are not showing because of partial return method -- shows on next refresh.
  end

  def unassigned_reorder
    @plan = find_plan
    unless params[:stage_id].blank?
      stage = @plan.stages.find(params[:stage_id])
      stage.unassign_request!([params[:request_id]]) if params[:request_id].present?
    end
    plan_release_details
    @default_stage = PlanStage.default_stage
    render :partial => "plans/members/list",
           :locals => {:stage => @default_stage, :grouped_members => @grouped_members, :plan => @plan }
  end

  def release_calendar
    if request.xhr?
      dates = params[:period].split(',').map(&:to_date)
      @plans = Plan.functional.with_plan_template("release_plan").having_release_date
      @plans = @plans.select { |lc| lc.has_app(params[:app_id]) } if params[:app_id].present?
      @plans = @plans.select { |lc|
        lc.release_date.between?(dates.first, dates.last)
      }.group_by { |lc| "#{lc.release_date.strftime('%B %Y')}" }
      @duration = @plans.keys.collect {|k| "#{k.split(' ').last}-#{Date::MONTHNAMES.index(k.split(' ').first)}-01".to_date}.sort
      render :partial => "plans/release_calendar/releases_by_month"
    end
  end

  def version_report
    @plan = find_plan
    plan_release_details
    @apps = @plan.applications
    if request.xhr?
      render :partial => "plans/version_report", :locals => { :plan => @plan, :apps => @apps }
    end
  end

  def environments_calendar
    @plans = Plan.functional
    @weeks, @months = {}, []
    for i in (-7..9)
      month = Date.today.beginning_of_month + i.month
      month_label = month.strftime('%b %Y')
      weeks = Calendar::Month.new(month).weeks
      @months.push(month_label)
      @weeks[month_label] = weeks.map(&:first_day).collect{|day|day.strftime('%m/%d')}
    end
  end

  def ticket_summary_report
    @app_id = params[:app_id]
    @plan = Plan.find(params[:id])
    render :template => "tickets/summary_rpt"
  end

  def ticket_summary_report_csv
    @plan = Plan.find(params[:id]) rescue nil
    @app_id = params[:app_id] rescue nil

    unless @plan.blank?
      @ticket_apps = App.find_all_by_id(@plan.tickets.map(&:app_id).uniq.reject{|k| k.nil? }).sort{ |a,b| a.name <=> b.name }
      @ticket_groups = (@app_id.nil? || @app_id == "all") ? @plan.tickets.group_by(&:app_id) : @plan.tickets.by_app_id(@app_id).group_by(&:app_id)
    end

       csvstring = CSV.generate do |csv|
          csv << ['App', 'Ticket ID', 'URL', 'Name', 'Runs', 'Requests', 'Type', 'Status']

            unless @ticket_groups.blank?
              @ticket_groups.each do |app_id,tickets|
                 tickets.each do |ticket|
                   csv << [(ticket.app) ? ticket.app.name : "",
                           ticket.foreign_id,
                           ticket.url,
                           ticket.name,
                           (@plan.runs.nil?) ? "" : run_name_list_for_app_with_ticket(@plan, (ticket.app.id unless ticket.app.nil?), ticket.id),
                           (ticket.app.nil?) ? "" : request_name_list_for_app_with_ticket(@plan, ticket.app.id, ticket.id),
                           ticket.ticket_type,
                           ticket.status]
                 end
              end
            end # unless
        end

        send_data csvstring, :type => 'text/csv', :filename => "ticket_summary_report.csv"
  end

  def delete_env_date
    @plan = Plan.find(params[:id]) rescue nil
    @env_app_date = PlanEnvAppDate.find(params[:plan_app_env_id])
    @env_app_date.destroy
  end

  # returns a partial for ajax calls to see a short list of constraint types
  def constraints
   @psi = PlanStageInstance.find(params[:plan_stage_instance_id])
   @constraints_by_type = @psi.constraints_by_type
   @constrainable_type = params[:constrainable_type]
   @plan = find_plan
   render :layout => false
  end

  private

  def read_only?
    @plan = Plan.find(params[:id]) rescue nil
    if @plan.archived?
      # flash[:error] = "Access Denied ! You do not   have adequate permissions to access the page you requested."
      flash[:error] = I18n.t(:'activerecord.notices.no_permissions', action: 'access', model: 'the page you requested.')
      redirect_to @plan
    end
  end

  def requests_in_plan_for_app_with_ticket(plan,app_id, ticket_id)
    @related_requests = plan.requests.with_app_id(app_id)
    @related_requests.select{|req| req.steps.select{ | stp | stp.has_ticket(ticket_id)}.count > 0  }
  end

  def request_name_list_for_app_with_ticket(plan,app_id, ticket_id)
    requests_in_plan_for_app_with_ticket(plan,app_id, ticket_id).map{ |req| req.number }.join("|")
  end

  def run_name_list_for_app_with_ticket(plan,app_id,ticket_id)
    plan.runs.select{ |cur_run| (requests_in_plan_for_app_with_ticket(plan,app_id, ticket_id) & cur_run.requests).count > 0 }.map{ |r| r.name}.join("|")
  end

  def selectbox_data
    @plan_templates = PlanTemplate.unarchived.visible.order("LOWER(name) asc")
    @release_managers = User.active.not_placeholder.index_order.select([:first_name, :last_name, :id, :type]).collect { |u| [u.name_for_index, u.id] }
    @teams = Team.order("LOWER(name) asc").collect
    @releases = Release.unarchived.order("LOWER(name) asc").collect { |r| [r.name, r.id] }
  end

  def path_for_tab(tab = "stages")
    return case tab
      when "stages"
        plan_path(@plan)
      when "calendar"
        calendar_months_path(:plan_id => @plan.id)
      when "versions"
        version_report_plan_path(@plan.id)
    end
  end

end
