################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ScriptsController < ApplicationController
  include ArchivableController
  include ControllerSharedScript
  include ObjectStateController

  skip_before_filter :authenticate_user!, :only => [:import_scripts_list]
  before_filter :find_integration, :only => [:find_jobs, :build_job_parameters]
  around_filter :timeout, :only => [:test_run]


  def new
    authorize! :create, :automation
    @script = Script.new
    render_new
  end

  def edit
    authorize! :edit, :automation
    begin
      @script = find_script
    rescue ActiveRecord::RecordNotFound
      flash[:error] = " script you are trying to access either does not exist or has been deleted"
      redirect_to(automation_scripts_path) && return
    end
    # @script.update_bladelogic_arguments if bladelogic?
    @store_url = true
    render_edit
  end


  def create
    authorize! :create, :automation
    @script = Script.new(params[:script])
    if @script.save
      request.xhr? ? ajax_redirect(index_path) : redirect_to(index_path)
    else
      @scripts = paginate_records(Script.all, params, 10)
      request.xhr? ? show_validation_errors(:script, {:div => "#{@script.class.to_s.underscore}_error_messages"}) : render_new
    end
  end

  # arguments are initialized for steps in the steps controller, but for tickets
  # and other resource automations we want to take advantage of the ajax loading
  # methods used in steps.js and requests.js, but have generic initialization
  # that does not requite a step or request to be passed in
  # this should be available at scripts/initialize_arguments and passed script_id
  # as a required parameter. The UI around this is a little convoluted and javascript
  # dependent so we are not able to use the script member url as the endpoint for the
  # form although that would be more accurate
  def initialize_arguments
    # first make sure there is a script
    script = Script.find(params[:script_id]) rescue nil
    unless script.blank?
      #script type may be passed, though if this routine is being used it is like a ResourceAutomation
      script_type = params[:script_type] || "ResourceAutomation"
      # consider mocking up a step for compatibility reasons until the automation
      # controls can be properly generalized.  Might be meaningful to also set the
      # script ids to something meaningful
      step = Step.new
      step.script_id = script.id
      step.script_type = script_type

      #
      # This is a HACK to make sure dependency loading
      # works when you load up a query in external tickets filters
      step.id = 0 if params[:query_mode] == "true"

      # we have some current argument values -- set perhaps by saved query -- to respect
      filled_argument_values = JSON.parse(params[:argument_values]) rescue nil

      # now render the generic form for automation properties to get the ball rolling
      render :partial => 'steps/step_script', :locals => { :script => script, :step => step, :installed_component => nil, :argument_values => filled_argument_values || script.filter_argument_values, :old_installed_component_id => nil }

    else
      # if something has gone very wrong and the @script is not found, show an error and send them to the home page
      flash[:error] = "Unable to find script for id: #{params[:script_id] || "blank"}"
      redirect_to root_url
    end
  end


  def update_script
    authorize! :edit, :automation
    @script = find_script
    if @script.update_attributes(params[:script])
      if request.xhr? && params[:do_not_render].blank?
        render :template => "shared_scripts/update"
      else
        redirect_to(index_path)
      end
    else
       # @scripts = paginate_records(Script.all, params, 10)
      request.xhr? ? show_validation_errors(:script, {:div => "#{@script.class.to_s.underscore}_error_messages"}) : render_edit
    end
  end

  def render_integration_header
    if params[:script_hash].present?
      @script = Script.new(params[:script_hash])
      @script.template_script = "#{@script.template_script_type}_#{@script.template_script_id}"
      @script.save
    end
    @script = params[:script_hash].present?  ? @script : Script.new
    @automation_type = params[:automation_type]
    render :template => "shared_scripts/script_integration_header.html.erb", :locals => { :automation_category => params[:script_type], :script => @script }, :layout => false
  end

  def render_automation_form
    if params[:script_hash]
      ignore_elements = %w(created_at id updated_at aasm_state)
      ignore_elements.each do |element|
        params[:script_hash].delete_if {|key, value| (key == element || value == 'null') }
      end
      if params[:script_hash].present?
        @script = Script.new(params[:script_hash])
        @script.save
      end
    end
    @script = params[:script_hash].present? ? @script : Script.new

    case params[:automation_type]
    when 'Automation'
      render partial: 'shared_scripts/automation_form', locals: { script: @script }
    when 'ResourceAutomation'
      render partial: 'scripted_resources/form', locals: { script: @script }
    else
      render partial: 'shared_scripts/automation_form', locals: { script: @script }
    end
  end

  # scripts/execute_mapped_resource_automation
  # for external ticket filters and other resource automations mapped to BRPM system models
  # this function accepts a typical automation argument form as input and runs the resource
  # automation, expecting a hash of the stated type in script.maps_to.
   def execute_mapped_resource_automation
     begin

       # pass along pagination controls
       page = params[:page].to_i
       per_page = params[:per_page].to_i
       offset = page * per_page

       # set up a dummy step
       step = Step.new

       # since this is a member url we should have the id in the url or throw a 404
       external_script = Script.find(params[:id])

       # cache the plan involved for later assignment to selected tickets
       plan = Plan.find(params[:plan_id]) if params[:plan_id].present?

       # prepare an argument hash
       argument_hash = {}

       # cycle through the form variables to see what has been set, ignoring blank values
       params[:argument].each do |key, value|
         argument_name = ScriptArgument.find(key).argument
         # guarantee that all values are an array
         value = Array(value)
         # select box values are coming through as single element arrays
         if value.length < 2
           argument_hash[argument_name] = value[0] unless value.blank? || value[0].blank?
         else
           # CHKME: Does AO allow arrays of values from a multi-select?
           argument_hash[argument_name] = value
         end
       end

       # Execute and fetch the resource automation output
       external_script_output =  view_context.execute_automation_internal(step, external_script, argument_hash, nil, offset, per_page)

       # for testing purposes construct the hash here
       # external_script_output =  {
       # :perPage => 5,
       # :totalItems => 100,
       # :data =>
       # [
         # ["ra_uniq_identifier","Foreign Id","Name","Ticket Type", "Status", "Status Label", "Extended Attributes"],
         # ["1","2","3","4","5","6","7"]
       # ]
       # }
       query_name = "#{external_script.project_server.name}: #{external_script.name}: #{Time.now.to_s(:short_audit)}"
       # now is a good time -- with a successful run we hope -- to save this query for later recall
       @query = plan.queries.create( :project_server => external_script.project_server,
                                     :name => query_name,
                                     :script => external_script,
                                     :user => User.current_user )
       # if that was successful, go ahead and add the arguments to the query details
       if @query
         argument_hash.each do |key, value|
           # FIXME: Type in schema for conjunction <> conjuction
           @query.query_details.create(:query_element => key, :query_criteria => "=", :query_term => value, :conjuction => 'AND')
         end
       end
       # cache the new saved queries so we can update the menu with this latest run
       # now see if there are any past queries
       saved_queries = plan.queries.where(:last_run_by => User.current_user.try(:id)).order('created_at DESC').limit(25)

       # send all this data to a js partial that will reload items as needed
       render :partial => 'shared_scripts/execute_mapped_resource_automation',
               :locals => { :external_script_output => external_script_output,
                            :project_server_id => external_script.integration_id,
                            :plan => plan, :saved_queries => saved_queries }
     rescue Exception => err
       log_automation_errors(step, err, external_script_output)
       render :text => ApplicationController.helpers.options_for_select([['N.A', '']])
     end
   end

  # This method will execute the resource automation which is dependent on some other field/argument
  def execute_resource_automation
    begin
      argument = ScriptArgument.find(params[:target_argument_id])
      external_script = Script.find_by_unique_identifier(argument.external_resource)
      external_script_output = execute_resource_automation_common(external_script, nil, 0, 0)
      logger.info "Resouce Automation Script Output: #{external_script_output.inspect}"
      use_selected_values = true
      params[:source_argument_value].each { |k, v|
        use_selected_values = false if @step.script_argument_value(k) != [v].flatten
      }
      if external_script.render_as == "Tree"
        tree_output = view_context.tree_type_argument(argument,external_script_output,params[:value], @step, external_script, params[:source_argument_value])
        render :text => tree_output
      elsif external_script.render_as == "Table"
        table_output = view_context.table_type_argument(argument,external_script_output,params[:value], @step, external_script, params[:source_argument_value], nil, use_selected_values)
        render :text => table_output
      else
        render :text => ApplicationController.helpers.options_for_select(external_script_output.try(:flatten_hashes), params[:value])
      end
    rescue Exception => err
      log_automation_errors(@step, err, external_script_output)
      render :text => ApplicationController.helpers.options_for_select([['N.A', '']])
    end
  end

  # Following methods will be only used for Hudson Automation Category

  def find_script_template
    return unless request.xhr?
    script = script_type(params[:id])
    render :text => script.content
  end

  def find_jobs
    return unless request.xhr?
    jobs = Script.get_hudson_jobs(@integration)
    job_options = jobs.collect{|j| "<option value='#{j}'>#{j}</option>"}
    render :text => "<option value=''>Select</option>" + job_options.join
  end

  def build_job_parameters
    return unless request.xhr?
    if (params[:script_id] && !params[:script_id].blank?)
      script = script_type(params[:script_id])
    end
    new_content = Script.hudson_parameters_to_arguments(params[:job], @integration, script.nil? ? "" : script.content)
    render :text => new_content
  end

  # This method will be called from an ajax call
  def update_resource_automation_parameters
    installed_component = InstalledComponent.find(params[:resource_installed_component_id]) if params[:resource_installed_component_id].present?
    old_installed_component_id = params[:resource_old_installed_component_id] || nil

    if params[:resource_step_id].present?
      step = Step.find(params[:resource_step_id])
    else
      # This means step object is a new record
      @request = Request.find(params[:resource_request_id]) if params[:resource_request_id].present?
      if @request.present?
        step = @request.steps.build
        step.component_id = params[:resource_component_id]
        step.installed_component_id = params[:resource_installed_component_id]
        step.script_id = params[:resource_script_id]
        step.script_type = params[:resource_script_type]
        step.owner = params[:resource_step_owner_type].constantize.find_by_id(params[:resource_step_owner_id]) unless params[:resource_step_owner_type].blank?
      end
    end
    script = Script.find(params[:resource_script_id])
    old_installed_component_hash = old_installed_component_id.nil? ? nil : {:old_installed_component_id => old_installed_component_id}
    argument_values = step.present? ? step.script_argument_values_display(old_installed_component_hash) : nil
    if request.xhr?
      arg_hsh = {}
      script.arguments.each do |argument|
        if argument.external_resource.present?
          new_argument_value = argument_values[argument.id]["value"] rescue nil
          ss = view_context.script_argument_value_input_display(step, argument, installed_component, new_argument_value, true)
          arg_hsh[argument.id] = ss
        end
      end
      render :json => arg_hsh.to_json
    end
  end

  def get_tree_elements
    @parent_id = params[:topLevel] ? '' : params[:key]
    @offset = 0
    @per_page = @per_page || 5
    external_script_output = execute_table_tree_automation
    if external_script_output.blank?
      external_script_output_loaded = []
    else
       external_script_output_loaded = external_script_output.collect{ |ext_srpt|
         unless ext_srpt.select{|k,v| k.to_sym.eql?(:hasChild)}.empty?
            ext_srpt.delete(:hasChild)
            ext_srpt.merge!({:isLazy => 'true'})

         end
         ext_srpt.merge!({:select => true}) if @value && @value.include?(ext_srpt[:key])
         ext_srpt
       }
    end
    respond_to do |format|
      format.json{  render :json => external_script_output_loaded.to_json }
    end
  end

  def get_table_elements
    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    @offset = @page * @per_page
    @container = params[:argument_id]
    @arg_val = (params[:argument_value] && !params[:argument_value].blank? && params[:argument_value].valid_json?) ? (params[:argument_value].is_a?(Hash) ? params[:argument_value] : JSON.parse(params[:argument_value])  ) : nil
    @parent_id = nil
    @external_script_output = execute_table_tree_automation
    respond_to do |format|
      format.js {  render :template => 'shared_scripts/get_table_elements.js.erb', :content_type => 'application/javascript' }
    end
  end

  def download_files
    begin
      # file = File.open("#{Rails.root}"+params[:path]).read if params[:path].present?
      # send_data file, :filename => "#{params[:path].split('/').last}" if file.present?
      if params[:path].present?
        file_path = "#{$OUTPUT_BASE_PATH}#{params[:path]}"
        send_file file_path, :filename => "#{params[:path].split('/').last}"
      end
    rescue Exception => e
      flash[:error] = "File you are trying to download either does not exist or has been deleted."
      redirect_to(root_url)
    end
  end

  protected

    def timeout
      #SystemTimer.timeout(30) do
      Timeout.timeout(300) do
        yield
      end
    end


  private

    def bladelogic?
      false
    end

    def render_new
      if params.include?("stand_alone")
        render :template => 'shared_scripts/new', :layout => false
      else
        if request.xhr?
          render :template => 'shared_scripts/detail_new', :layout => false
        else
          render :template => 'shared_scripts/detail_new'
        end
      end
    end

    def render_edit
      if request.xhr?
        render :template => 'shared_scripts/edit', :layout => false
      else
        render :template => 'shared_scripts/detail_edit'
      end
    end

    def find_integration
      @integration = ProjectServer.find(params[:id])
    end

    def script_type(script_id)
      @script = Script.find(script_id)
    end

    def execute_resource_automation_common(external_script, parent_id, offset, per_page)
      params[:source_argument_value] = {} if params[:source_argument_value].blank? || (params[:source_argument_value] == "null")
      params[:source_argument_value] = JSON.parse(params[:source_argument_value]) unless params[:source_argument_value].is_a?(Hash)

      argument_hash = {}
      params[:source_argument_value].each do |key, value|
        argument_name = ScriptArgument.find(key).argument
        argument_hash[argument_name] = value
      end

      if params[:step_obj].blank? || (params[:step_obj] == "null")
        step = Step.new
      else
        params[:step_obj] = JSON.parse(params[:step_obj]) unless params[:step_obj].is_a?(Hash)
        # This will not be required if we remove unwanted columns from db, as they are being deleted from model attr_accessible
        params[:step_obj] = params[:step_obj].delete_if do |key, value|
          (["change_request_id", "custom_ticket_id", "on_plan", "release_content_item_id"].include?(key) || value.blank? || value == "null")
        end

        step = Step.find_or_initialize_by_id(params[:step_obj][:id]) { |step| step.assign_attributes(params[:step_obj]) }
        if step.persisted?
          step.component_id = params[:step_obj][:component_id]
          step.installed_component_id = params[:step_obj][:installed_component_id]
        end
      end

      @step = step
      view_context.execute_automation_internal(step, external_script, argument_hash, parent_id, offset, per_page)
    end


    def execute_table_tree_automation
      argument = ScriptArgument.find(params[:argument_id])
      external_script = Script.find_by_unique_identifier(argument.external_resource)
      external_script_output = execute_resource_automation_common(external_script, @parent_id, @offset, @per_page)
      val = params[:value]
      unless val.blank?
        val = [ val.split(',') ].flatten
      end
      @value = val || [view_context.script_argument_value_input_tag_value(@step, argument, @step.installed_component)].flatten
      external_script_output
    end

    def use_template
     'automation_scripts'
    end

end
