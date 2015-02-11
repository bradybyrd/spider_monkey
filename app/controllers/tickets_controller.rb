################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class TicketsController < ApplicationController
  include ApplicationHelper
  include TicketsHelper

  before_filter :find_ticket, :only => [:edit, :update, :destroy]
  before_filter :find_plan_and_ticketing_project_servers, :only => [:index, :query]
  before_filter :ticket_filter_session, :only => :index

  def index
    authorize_action
    # cache the actions to determine what action columns to show on the ticket list
    @actions = params[:actions] || ['delete']

    @search_keyword=params[:key] if params[:key].present?
    params[:filters] = params[:filters] || {}
    # Default sorting assignment
    if params[:filters][:sort_scope].blank? || params[:filters][:sort_scope] == 'false'
      params[:filters][:sort_scope] = 'foreign_id'
      params[:filters][:sort_direction] = current_user.list_order
    end
    # first test is we want to show the unpaged view -- step tabs seems to call this
    if @actions && @actions.include?('unpaged')
      @tickets = []
      @tickets = Ticket.find(params['ticket_ids']) if params['ticket_ids']
      render :partial => 'tickets/unpaged_tickets_table', :locals => {:tickets => @tickets }
    elsif request.xhr? && @actions.include?('select')
      # this seems to be a javascript call (steps?) for selecting tickets and associating them from the step facebox
      @current_tickets = params[:current_tickets] ? params[:current_tickets].split(',').map{|t| t.to_i} : []
      if params[:filters][:plan_association] && (params[:filters][:plan_association].include?("Selected") && !params[:filters][:plan_association].include?("Unselected"))
        available_tickets = Ticket.include_only(@current_tickets)
      elsif params[:filters][:plan_association] && (!params[:filters][:plan_association].include?("Selected") && params[:filters][:plan_association].include?("Unselected"))
        available_tickets = Ticket.exclude_only(@current_tickets)
      else
      available_tickets = []
      end

      @per_page = params[:per_page].nil? ? 20 : params[:per_page]
      @tickets = paginate_tickets(available_tickets, @per_page, nil)

      respond_to do |format|
        if params[:step_facebox].present?
          format.js { render :template => 'tickets/select_tickets_list', :handlers => [:erb], :content_type => 'application/javascript'}
        else
          format.html {render :partial => "tickets/select_tickets_list_in_facebox", :locals => {:tickets => @tickets }}
        #format.html {render :text => "tickets/select_tickets_list"}
        end
      end

    elsif @plan_id.present?
      # add the plan id to the filters because this controller uses an unusual pagination
      # routine to do the filters
      # FIXME: ideally, params should not be accessed in the helpers
      # like this but rather passed explicitly in the method
      params[:filters] = params[:filters] || {}
      params[:filters][:plan_id] = @plan_id if params[:filters][:plan_id].blank?
      @per_page = params[:per_page].nil? ? 20 : params[:per_page]
      @tickets = paginate_tickets(nil, @per_page, nil)
      # set the selected tab
      @page_tab_selected = 'tickets'
      respond_to do |format|
        if request.xhr?
          # pagination request so just send partial
          format.html { render :partial => "tickets/tickets_list", :locals => { :tickets => @tickets, :plan => @plan } }
        else
          # regular page index so do the whole template
          format.html { render :template => "plans/show", :locals => { :tickets => @tickets } }
        end
      end
    else
      # default action from the environments tab
      @per_page = 20
      @tickets = paginate_tickets(@tickets, @per_page, @search_keyword)
      respond_to do |format|
        if request.xhr?
          # pagination request so just send partial
          format.html { render :partial => "tickets/tickets_list", :locals => { :tickets => @tickets } }
        else
          # regular page index so do the whole template
          format.html
        end
      end
    end
  end

  def new
    unless params[:project_server_id].blank?
      @ticket = Ticket.new(:project_server_id => params[:project_server_id])
    else
      @ticket = Ticket.new
    end
    authorize! :create, @ticket
    if request.xhr?
      render :partial => "tickets/form", :locals => { :ticket => @ticket, :backlink => tickets_path }
    end
  end

  def edit
    authorize! :edit, @ticket
    @backlink = params[:backlink].nil? ? tickets_path : params[:backlink]
    if request.xhr?
      unless params[:project_server_id].blank?
        p = ProjectServer.find(params[:project_server_id]) rescue nil
        unless p.blank?
        @ticket.project_server = p
        end
      end
      render :partial => "tickets/form", :locals => { :ticket => @ticket, :backlink => @backlink }
    end
  end

  def create
    @ticket = Ticket.new(params[:version])
    authorize! :create, @ticket

    @ticket.update_attributes(params[:ticket])
    if @ticket.save
      flash[:notice] = 'Ticket was successfully created.'
      redirect_to tickets_path
    else
      render :action => "new"
    end
  end

  def update
    authorize! :edit, @ticket
    if @ticket.update_attributes(params[:ticket])
      flash[:notice] = 'Ticket was successfully updated.'
      redirect_to tickets_path
    else
      @backlink = tickets_path
      render :action => "edit"
    end
  end

  def destroy
    authorize! :delete, @ticket
    # we might be coming in from a plan member so get the plan id
    @plan_id = params[:plan_id]
    @ticket.destroy
    if @ticket
      @ticket.destroy rescue false
    end
    if request.xhr?
      render :template => 'tickets/destroy_ticket'
    elsif @plan_id
      redirect_to tickets_plan_path(@plan_id)
    else
      redirect_to tickets_path
    end
  end

  # this action presents a query interface for external ticket sources
  # and is usually called from the Plan Tickets screen.  It may also be called
  # from the tickets metadata screen if development schedules allow that expansion
  def query

    # now see if there are any past queries and be sure to check if they are still mapped to queries
    saved_queries = @plan.queries.mapped_to_ticketing.where(:last_run_by => User.current_user.try(:id)).order('queries.created_at DESC').limit(25)
    # trim out any that might refer to invalid servers
    saved_queries.select! { |q| @project_servers.include?(q.project_server) }

    # provide a little dummy data (headers) to initialize the table control
    # and hold the place on the screen
    header_data = [["ra_uniq_identifier","Foreign Id","Name","Status", "Ticket Type","Extended Attributes"]]
    external_script_output = { :perPage => 25,
      :totalItems => 0,
      :data => header_data }
    if request.xhr?
      render :partial => "tickets/query", :locals => { :plan => @plan,
                                          :project_servers => @project_servers,
                                          :external_script_output => external_script_output,
                                          :saved_queries => saved_queries }
    end
  end

  def resource_automations

    @project_server_id = params[:project_server_id]

    # see if being called from a plan
    plan_id = params[:plan_id]
    plan = Plan.find(plan_id) if plan_id.present?

    if @project_server_id.present?
      @project_server = ProjectServer.find(@project_server_id)
      @resource_automations = @project_server.scripts.ticketing_automations
    end
    if @resource_automations.present?
      if request.xhr?
        render :partial => "tickets/resource_automations", :locals => { :project_server => @project_server, :resource_automations => @resource_automations, :plan => plan }
      end
    else
      flash.now[:error] = "Unable to find resource automations for project server id: #{ @project_server_id || 'blank'}."
      render :nothing => true
    end
  end

  # once a resource automation is picked from the pull down menu, we load the arguments using similar logic as test automations
  def filter_arguments
    # see if being called from a plan
    plan_id = params[:plan_id]
    plan = Plan.find(plan_id) if plan_id.present?

    # check for a query id which can be used to pull up the script from memory and pass some arguments
    @query_id = params[:query_id]
    if @query_id.present?
      @query = Query.find(@query_id)
      if @query.present?
        # set these values from the query
        @project_server = @query.project_server
        @script = @query.script
        # also look for saved arguments
        prefilled_argument_values = @script.filter_argument_values
        details = @query.query_details
        if details.present?
          details.each do |detail|
          # look up the argument with the script and the name
            @argument = ScriptArgument.where(:script_id => @script.id, :argument => detail.query_element).first
            prefilled_argument_values[@argument.id]["value"] = detail.query_term if @argument
          end
        end
      end
    else
      @script_id = params[:script_id]
      if @script_id.present?
        @script = Script.find(@script_id)
      end
      # also look for saved arguments
      prefilled_argument_values = @script.filter_argument_values
    end

    if @script.present?

      #script type may be passed, though if this routine is being used it is like a ResourceAutomation
      script_type = params[:script_type] || "ResourceAutomation"
      # consider mocking up a step for compatibility reasons until the automation
      # controls can be properly generalized.  Might be meaningful to also set the
      # script ids to something meaningful
      step = Step.new
      step.script_id = @script.id
      step.script_type = @script_type

      if request.xhr?
        render  :partial => "tickets/filter_arguments",
                :locals => {
                  :project_server => @project_server,
                  :script => @script,
                  :argument_values => prefilled_argument_values,
                  :step => step,
                  :plan => plan,
                  :query => @query,
                  :installed_component => nil,
                  :old_installed_component_id => nil },
                :layout => false
      end
    else
      flash.now[:error] = "Unable to find ticket filter with script id: #{ @script_id || 'blank'}."
      render :nothing
    end
  end

  # after being selected, the form sends an array of post data with the external tickets
  def add_selected_external
    # grab the target plan
    @plan = Plan.find(params[:plan_id]) unless params[:plan_id].blank?
    @project_server = ProjectServer.find(params[:project_server_id]) unless params[:project_server_id].blank?
    if @plan.present? && @project_server.present?
      # grab the potential tickets from the hidden argument inputs organized by the passed in argument_id of 1, doing nothing if blank
      selected_tickets = params[:argument]['1']
      ticket_cache = params[:cached_data]['1']
      if selected_tickets.present? && ticket_cache.present?
        @results = Ticket.add_tickets_to_plan(@plan, @project_server, selected_tickets, ticket_cache)
        # let the user know how things went in a flash message
        @message = "Import completed: #{@results[:updated_tickets].length} updated, #{@results[:created_tickets].length} created, and #{@results[:invalid_ticket_data].length} invalid tickets."
      else
        @message = "We could not locate any tickets selected for import."
      end
      @path = tickets_plan_path(@plan)
    else
      # we are missing key data so redirect to the plans index page
      @message = "Unable to find a plan ID #{ params[:plan_id] || 'blank'} and/or project_server #{ params[:project_server_id] || 'blank'} ."
      @path = plans_path
    end

    redirect_to @path, :notice => @message
  end

  protected

  # in any case show the query interface by gathering project servers first
  # had to hack this because Oracle cannot return distinct on clob records
  # so we have to return just the ids in a distinct query, then find the full
  # objects in another query -- https://github.com/rsim/oracle-enhanced/issues/112
  def find_plan_and_ticketing_project_servers
    # plan finder moved here so we can remove any server associated with the plan
    # we might be coming in from a plan member so get the plan id
    @plan_id = params[:id] || params[:plan_id] || params[:filters][:plan_id]

    @plan = Plan.find(@plan_id) unless @plan_id.blank?

    ps_ids = ProjectServer.active.ids_with_ticketing_automations.map(&:id)
    @exclude_project_server = [@plan.try(:project_server_id)] == ps_ids
    @project_servers = ProjectServer.active.where('project_servers.id' => ps_ids)
    # if we have a plan and the plan has been externally created and associated with a server, remove it from this list
    @project_servers.reject! {|ps| ps.id == @plan.project_server_id } if @plan.present? && @plan.project_server_id.present?
    # count the number of ticketing servers to see if we should show the external filters link
    @ticketing_project_server_count = @project_servers.length
  end

  def find_ticket(return_new = false)
    if params[:id].nil? && return_new
      @ticket = Ticket.new
    else
      begin
        @ticket = Ticket.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Ticket you are trying to access either does not exist or has been deleted"
        redirect_to(root_path) && return
      end
    end
  end

  def ticket_filter_session
    session[:ticket_filter_session] ||= HashWithIndifferentAccess.new
    if params[:filters].present? && !params[:filters][:plan_id].present?
      session[:ticket_filter_session] = params[:filters]
    elsif (params[:filters].present? && params[:filters][:plan_id].present?) || params[:id]
    else
      params[:filters] = session[:ticket_filter_session]
    end
  end

  def authorize_action
    if @plan_id.present?
      authorize! :list_plan_tickets, Ticket.new
    else
      authorize! :list, Ticket.new
    end
  end

end
