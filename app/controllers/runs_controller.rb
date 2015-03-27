class RunsController < ApplicationController
  layout :choose_layout

  before_filter :find_plan_and_plan_stage
  before_filter :get_select_box_data, :only => [:new, :edit, :create, :update]
  skip_before_filter :verify_authenticity_token, :only => [:drop]

  # GET /runs
  # GET /runs.xml
  def index
    @runs = Run.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @runs }
    end
  end

  # GET /runs/1
  # GET /runs/1.xml
  def show
    @run = Run.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @run }
    end
  end

  # GET /runs/new
  # GET /runs/new.xml
  def new

    # check for promotion
    @request_ids = case
                     when params[:next_required_stage_id] && params[:run_to_clone_id]
                       @next_required_stage_id = params[:next_required_stage_id]
                       @next_required_stage = PlanStage.find(@next_required_stage_id) unless @next_required_stage_id.blank?
                       @run_to_clone_id = params[:run_to_clone_id]
                       @run_to_clone = Run.find(@run_to_clone_id) unless @run_to_clone_id.blank?
                       @run_to_clone.requests.complete.all.try(:map, &:id)
                     when params[:request_ids]
                       @request_ids = params[:request_ids]
                     else
                       @plan_stage.requests.map(&:id)
                   end

    # get just the first ten requests selects for display to avoid blowing out of facebox
    @requests = Request.where(:id => @request_ids).order("requests.name") rescue [] unless @request_ids.blank?

    # reset the plan stage value to the next one if a promotion
    @plan_stage = @next_required_stage if @next_required_stage

    # build the run with the passed parameters
    @run = Run.new(:plan => @plan, :plan_stage => @plan_stage, :requestor => current_user, :request_ids => @request_ids ) unless @requests.blank? || @plan.blank? || @plan_stage.blank?

    # suggest environments based on routes if any
    @plan_stage_instance = @plan.plan_stage_instances.where(:plan_stage_id => @plan_stage.try(:id)).try(:first)

    respond_to do |format|
      if @run
        if request.xhr?
          format.html
        else
          format.html
          format.xml  { render :xml => @run }
        end
      else
        format.html { redirect_to(plan_path(@plan), :error => 'Run could not be created due to invalid parameters.') }
        format.xml  { head :unprocessable_entity }
      end
    end
  end

  # GET /runs/1/edit
  def edit
    authorize! :edit_runs, @plan
    @run = Run.find(params[:id])
    @requests = @run.requests
    @plan_stage = @run.plan_stage
  end

  # POST /runs
  # POST /runs.xml
  def create
    authorize! :create_run, @plan
    @run = Run.new(params[:run])

    @run.start_at_to_earliest_planned_at = params[:run_start_at_to_planned_at_earliest_request]
    @run.request_planned_at_to_run_start_at = params[:request_planned_at_to_run_start_at]
    params[:run] = reformat_dates_for_save(params[:run])

    @run.requests_planned_date = if params[:request_planned_at_to_run_start_at]
      {}
    else
      params[:run][:requests_planned_date] || {}
    end
    @run.should_time_stitch = true
    respond_to do |format|
      if @run.update_attributes(params[:run])
        path = plan_path( @plan, :run_id => @run.id )
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => 'Run was successfully created.') }
          format.xml  { render :xml => @run, :status => :created, :location => @run }
        end
      else
        if request.xhr?
          format.html { show_validation_errors(:run, {:div => 'run_error_messages'}) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /runs/1
  # PUT /runs/1.xml
  def update
    authorize! :edit_runs, @plan
    authorize! :plan_run, @plan
    authorize! :start_run, @plan
    authorize! :hold_run, @plan
    authorize! :cancel_run, @plan

    @run = Run.find(params[:id])
    @requests = @run.requests
    @plan_stage = @run.plan_stage
    @run.start_at_to_earliest_planned_at = params[:run_start_at_to_planned_at_earliest_request]
    if params[:run][:start_at_date] || params[:run][:start_at_hour] || params[:run][:start_at_minute] || params[:run][:start_at_meridian] ||
        params[:run][:end_at_date] || params[:run][:end_at_hour] || params[:run][:end_at_minute] || params[:run][:end_at_meridian]
      @run.should_time_stitch = true
    end

    respond_to do |format|
      @run.attributes = reformat_dates_for_save(params[:run])
      if @run.update_attributes(params[:run])
        update_request_planned_date(params) unless params[:run][:aasm_event]
        unless @run.aasm_state == 'deleted'
          path = plan_path( @plan, :run_id => @run.id )
        else
          path = plan_path( @plan)
          # added to remove run id from variouse filter sesssions
          remove_run_from_filter_sessions
        end
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => "Run was successfully #{ @run.aasm_state == 'deleted' ? 'deleted' : 'updated' }.") }
          format.xml  { render :xml => @run, :status => :created, :location => @run }
        end
      else
        if request.xhr?
          format.html { show_validation_errors(:run, {:div => 'run_error_messages'}) }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def start
    authorize! :start_run, @plan
    run = Run.find(params[:id])
    if run.requests_have_notices?
      render json: {errors: run.requests_notices_message.split("\n")}
    else
      if run.start!
        render json: {url: plan_path(@plan, :run_id => run.id)}
      else
        render json: {errors: run.errors.messages.to_a}
      end
    end
  end

  # DELETE /runs/1
  # DELETE /runs/1.xml
  def destroy
    @run = Run.find(params[:id])
    @run.destroy

    respond_to do |format|
      format.html { redirect_to( plan_url(@plan) ) }
      format.xml  { head :ok }
    end
  end

  # accepts and array of run ids and builds a form for their inclusion in a selected run
  def select_run_for_ammendment
    authorize! :add_to_run, @plan
    @plan_stage_instance = @plan.plan_stage_instances.where(:plan_stage_id => @plan_stage.try(:id)).try(:first)
    # find available runs
    @runs = Run.by_plan_and_stage(@plan.id, @plan_stage.id).mutable.map { |r| [r.name, r.id] }
    # grab the selected requests or all the requests in the stage if none are selected
    @request_ids = params[:request_ids].blank? ? @plan_stage.requests.map(&:id) : params[:request_ids]
    # get just the first ten requests selects for display to avoid blowing out of facebox
    @requests = Request.find(:all, :conditions => { :id => @request_ids }, :order => "requests.name") rescue [] unless @request_ids.blank?
    respond_to do |format|
      if @runs
        format.html
        format.xml  { render :xml => @run }
      else
        format.html { redirect_to(plan_path(@plan), :error => 'Requests or runs were unavailable for linking.') }
        format.xml  { head :unprocessable_entity }
      end
    end
  end

  # special method to display short form of available runs and allow the user to add the run
  def add_requests
    # grab the selected requests or all the requests in the stage if none are selected
    @request_ids = params[:request_ids].blank? ? @plan_stage.requests.map(&:id) : params[:request_ids]
    # find the run
    @run = Run.find(params[:run_id]) rescue nil
    @run.requests_planned_date = if params[:request_planned_at_to_run_start_at]
      {}
    else
      params[:run][:requests_planned_date] || {}
    end
    respond_to do |format|
      if @run && @run.update_attributes(:request_ids => @request_ids)
        path = plan_path( @plan, :run_id => @run.id )
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => 'Requests were successfully added to run.') }
          format.xml  { render :xml => @run, :status => :created, :location => @run }
        end
      else
        format.html { redirect_to(plan_path( @plan ), :error => 'Sorry! Requests could not be added to run.') }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # accepts an array of request ids and drops them from their runs by nullifying that link, returning them to unassigned
  def drop
    authorize! :drop_from_run, @plan
    # grab the selected requests or all the requests in the stage if none are selected
    @request_ids = params[:request_ids]
    logger.info("Request Ids: " + @request_ids.inspect )
    # get just the first ten requests selects for display to avoid blowing out of facebox
    @requests = Request.find(@request_ids) unless @request_ids.blank?
    logger.info("Requests: " + @requests.inspect )
    # cycle through the requests and nullify their run on their members
    lm_ids = @requests.map(&:plan_member_id).uniq.sort unless @requests.blank?
    # check for a passed run
    @run_id = params[:run_id]
    # get the set of members to nullify
    PlanMember.update_all('run_id = NULL', ['plan_members.id IN (?)', lm_ids ] ) unless lm_ids.blank?
    respond_to do |format|
      path = @run_id.blank? ? plan_path( @plan ) : plan_path( @plan, :run_id => @run_id )
      unless lm_ids.blank?
        format.html { redirect_to(path, notice: I18n.t('run.notices.dropped_successfully')) }
        format.xml  { render :xml => @run, :status => :created, :location => @run }
      else
        format.html { redirect_to(path, :error => 'Sorry! Requests could not be dropped from associated runs.') }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # prepares for the reorder interface screen
  def reorder_members
    authorize! :reorder_run, @plan
    @run = Run.find(params[:id])
    @first_member = @run.plan_members.first
    @first_member.heal_positions if @first_member
    respond_to do |format|
      unless @run.blank?
      format.html
      else
        format.html { redirect_to(plan_path( @plan ), :error => "Sorry! Run not found for id #{params[:id]}.") }
      end
    end
  end

  # accepts reordering drag and drop from reorder screen
  def update_member_order
    authorize! :reorder_run, @plan
    @run = Run.find(params[:id])
    @member = PlanMember.find(params[:plan_member_id])
    @member.update_attributes(params[:plan_member])
    render :partial => 'for_reorder', :locals => { :run => @run, :member => @member }
  end

  # report to show versions of components in a run and highlight conflicts
  def version_conflict_report
    # find the run
    @run = Run.find(params[:id])
    @steps = Step.version_conflicts_for_run(@run.id).should_execute
    render :template => "runs/version_conflict_report"
  end



  def update_request_planned_date(params)
    @run.should_time_stitch = true
    scheduled_date_for_cloned_request = {}
    @run.requests_planned_date = if params[:request_planned_at_to_run_start_at]
      {}
    else
      params[:run][:requests_planned_date] || {}
    end
    @run.requests.each do |request|
      scheduled_date_for_cloned_request = @run.requests_planned_date.values_at(request.id.to_s).first if @run.requests_planned_date.present?
      @run.set_scheduled_date(request, scheduled_date_for_cloned_request)
    end
    @run.should_time_stitch = false
    @run.update_attribute(:start_at, @run.reload.requests.map(&:scheduled_at).compact.sort { |x, y| x <=> y }.first) if @run.start_at_to_earliest_planned_at
  end


  private

  def find_plan_and_plan_stage
    @plan = Plan.find_by_id(params[:plan_id]) rescue nil
    @plan_stage = PlanStage.find_by_id(params[:plan_stage_id]) rescue nil
  end

  def get_select_box_data
    @owners = User.active.order("users.last_name").not_placeholder.collect { |u| [u.name_for_index, u.id] }
  end

  def choose_layout
    (request.xhr?) ? nil : 'application'
  end

  def remove_run_from_filter_sessions
    session[:dashboard_request_dashboard][:plan_run_id].delete(@run.id.to_s) if session[:dashboard_request_dashboard].present? && session[:dashboard_request_dashboard][:plan_run_id].present?
    session[:dashboard_self_services][:plan_run_id].delete(@run.id.to_s) if session[:dashboard_self_services].present? && session[:dashboard_self_services][:plan_run_id].present?
    session[:calendar_session][:plan_run_id].delete(@run.id.to_s) if session[:calendar_session].present? && session[:calendar_session][:plan_run_id].present?
  end

end
