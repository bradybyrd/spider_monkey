################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class RestController < ApplicationController

  include ParamsMerger

  skip_before_filter :authenticate_user!
  before_filter :validate_api_filter, :except => [:validation_error]

  layout false
  
  # Returns ssh automation scripts
  #  
  # ==== Attributes  
  # 
  # * +format+ - be sure to add ".xml" to the method name 
  # * +token+ - your API Token for authentication  
  #  
  # ==== Raises  
  #  
  # * ERROR 403 Forbidden - When the token is invalid.  
  # * SUCCESS 204 No Content - When no scripts are found. 
  #  
  # ==== Examples  
  #   
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #  
  #   curl http://[rails_host]/REST/ssh_scripts.xml?token=[api_token] 
  def ssh_scripts
    scripts = CapistranoScript.order('capistrano_scripts.name asc')
    respond_to do |format|
      unless scripts.empty?
        format.xml { render :xml => scripts }
      else
        format.xml { render :xml => "<xml><success><response>No content.</response></success></xml>", :status => :no_content }
      end
    end
  end

  # Get template scripts, called by remote ss server
  #  
  # ==== Attributes  
  # 
  # * +format+ - be sure to add ".xml" to the method name 
  # * +token+ - your API Token for authentication  
  #  
  # ==== Raises  
  #  
  # * ERROR 403 Forbidden - When the token is invalid.  
  # * SUCCESS 204 No Content - When no scripts are found. 
  #  
  # ==== Examples  
  #   
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #  
  #   curl http://[rails_host]/REST/scripts/get_template_scripts.xml?token=[api_token] 
  def get_template_scripts
    scripts = Script.tagged_as_template
    respond_to do |format|
      unless scripts.empty?
        format.xml { render :xml => scripts.to_xml( :only => [:id, :name, :description, :script_type]) }
      else
        format.xml { render :xml => "<xml><success><response>No content.</response></success></xml>", :status => :no_content }
      end
    end

  end

  def get_script
    # Called by remote ss server
    unless validate_token.nil?
      valid_types = ["CapistranoScript", "BladelogicScript", "HudsonScript"]
      if valid_types.include?(params[:script_type])
        script_class = params[:script_type].constantize
        script = script_class.find(params[:script_id])
        general_error("Script with ID = #{params[:script_id]} not found") if script.nil?
        render :xml => script
      else
        err = "Script type: #{params[:script_type]} is not a valid script type. Allowed: #{valid_types.join(", ")}"
        general_error(err) if script.nil?
      end
    else
      validation_error
    end
  end

  def running_steps
    if !validate_token.nil?
      respond_to do |format|
        format.xml do
          render :xml => Step.running
        end
      end
    else
      validation_error
    end
  end

  def step_callback
    # URL: http://localhost:3000/steps/5309/1406/callback.xml?token=406_5309_1298032136
    @step = Step.find_by_id(params[:id].to_i)
    # logger.info "Current Step: #{@step.name}, Full URL:: #{request.url}"

    token = params[:token]
    chk_step = Step.find_by_token(token)
    # logger.info "State: #{@step.aasm_state.downcase}, ChkStep: #{chk_step.name}, Params: #{params.inspect}"
    status_msg = "Status: REST call "
    if !chk_step.nil? && @step.aasm_state.downcase == "in_process"
      if params[:rest_action].downcase == "set_state"
        case params[:value].downcase
        when "problem"
          @step.problem!
        end
        @step.notes.create(:content => "REST Message: #{CGI::unescape(params["note"])}", :user_id => @step.request.user_id) unless params["note"].nil?
      end
    else
      status_msg += "Token didn't match " if chk_step.nil?
      status_msg += "Step not in process (#{@step.aasm_state.downcase}) "
    end
    #Handle rest callbacks from scripts
    render :template => 'steps/script_callback.builder', :locals => { :message => status_msg }
  end

  def properties_inspector
    # la di da
  end

  def create_request_from_template
    unless validate_token.nil?
      begin
        @message = "Creating Request from template: #{params[:request_template]} on #{Time.now.to_s}\n"
        merge_params_create_request_from_template
        request_from_template
        if @request
          update_attributes = ""
          if params[:component_id].present?
            update_attributes += "steps.component_id = '#{params[:component_id]}'"
          end
          if params[:component_version].present?
            update_attributes += "#{update_attributes == "" ? "" : ", "} steps.component_version = '#{params[:component_version]}'"
          end
          @request.steps.update_all(update_attributes) unless update_attributes.blank?
          if params[:auto_start].present?
            @message += ", Auto-Starting request"
            update_request_state("start")
          end
          render :template => 'requests/show.builder'
        else
          @message += "Unable to create request from template "
        end
      rescue Exception => e
        error_message(e.message) #e.backtrace for details
      end
    else
      validation_error
    end
  end

  def change_component
    if !validate_token.nil? && find_request
      begin
        update_attributes = ""
        if params[:name].present?
          comp_id = Component.find_by_name(params[:name]).try(:id)
          unless comp_id.nil?
            if params[:replace].present?
              replace_id = Component.find_by_name(params[:replace]).try(:id)
            end
            if params[:version].present?
              version = params[:version]
            end
            @request.steps.find(:all, :conditions => "component_id=#{comp_id}").each do |step|
              step.component_id = replace_id unless replace_id.nil?
              step.component_version = version unless version.nil?
              step.save
            end
            @request.set_commit_version_of_steps
            render :template => 'requests/change_component.builder'
          else
            error_message("Unable to find component: #{params[:name]}")
          end
        else
          error_message("No component specified: #{params[:name]}")
        end
      rescue Exception => e
        error_message(e.message)
      end
    else
      validation_request_error
    end
  end

  def add_step
    if !validate_token.nil? && find_request
      begin
        update_attributes = ""
        if ["created", "planned", "hold"].include?(@request.aasm_state)
          if params[:component].present?
            comp_id = Component.find_by_name(params[:component]).try(:id)
            unless comp_id.nil?
              @message = "Adding Step: #{params.inspect}"
              version_tag_id = nil
              version = params[:component_version] if params[:component].present?
              version = "" if version.nil?  
              if params[:version_tag].present? && params[:component].present?
                version_tag = VersionTag.find_by_name(params[:version_tag])
                version = version_tag.try(:name) if version_tag
                version_tag_id = version_tag.id if version_tag
              end
              step_name = params[:name] if params[:name].present?
              total_steps = @request.steps.size
              position = params[:position] if params[:position].present?
              position = total_steps + 1 if (position.nil? || position.to_i > total_steps)
              script = find_script(params[:script]) if params[:script].present?
              app_id = App.find_by_name(params[:app]).try(:id) if params[:app].present?
              app_id = @request.apps[0].id if app_id.nil?
              app_comp = ApplicationComponent.find_by_app_id_and_component_id(app_id,comp_id)
              app_env = ApplicationEnvironment.find_by_app_id_and_environment_id(app_id, @request.environment.id)
              ic = InstalledComponent.find_by_application_component_id_and_application_environment_id(app_comp.id, app_env.id)
              #new_step = Step.create(
              version = version_tag.nil? ? () : version_tag.name
              step_params = {
              :request_id => @request.id,
              :component_id => comp_id,
              :installed_component_id => ic.id,
              :owner_id => User.current_user.id,
              :owner_type => "User",
              :component_version => version,
              :version_tag_id => version_tag_id,
              :position => position,
              :app_id => app_id
              }
              logger.info "SS__ Creating Step: #{step_params.inspect}"
              new_step = Step.create(step_params)
              new_step.name ||= step_name
              unless script.nil?
              new_step.manual = false
              new_step.script_id = script.id
              new_step.script_type = script.class.to_s
              else
                @message += "\nUnable to find script: #{params[:script]}"
              end
              new_step.save(:validate => false)
              arguments_hash = {}
              unless script.nil? || script.arguments.blank?
                script.arguments.each do |arg|
                  new_step.step_script_arguments.create!(:script_argument => arg, :value => arg.values_from_properties(ic).first) if arg
                end
              end
              @message += "\nNew Step ID=#{new_step.id.to_s}, #{@message}"
              render :template => 'requests/add_step.builder'
            else
              error_message("Unable to find component: #{params[:component]}")
            end
          else
            error_message("No component specified: #{params[:component]}")
          end
        else
          error_message("Request must be in design state (created/planned/hold) to add steps")
        end
      rescue Exception => e
      #error_message(e.message)
        error_message(e.backtrace.join("\n"))
      end
    else
      validation_request_error
    end
  end

  def update_step_state
    # blahblah/REST/steps/5534/update_step_state?token=ajkfhgag;ad295jaljk&transition=start
    if !validate_token.nil?  && find_step
      begin
        unless @step.nil?
          transition = params[:transition].to_s
          @message = "Updating step state: change to: #{transition} from: #{@step.aasm_state}"
          @transition_successful = case transition
          when 'done' then @step.all_done!
          when 'problem' then @step.problem!
          end
          if @transition_successful
            render :template => 'steps/show.builder'
          else
            render_xml_with_request_number("Step state could not be changed to #{params[:transition]}\n")
          end
        end
      rescue Exception => e
        error_message(e.message)
      end
    else
      validation_request_error
    end
  end

  def update_state
    if !validate_token.nil?  && find_request
      begin
        update_request_state
        if @transition_successful
          render :template => 'requests/show.builder'
        else
          render_xml_with_request_number("Request state could not be changed to #{params[:transition]}\n")
        end
      rescue Exception => e
        error_message(e.message)
      end
    else
      validation_request_error
    end
  end

  def request_status
    if !validate_token.nil?  && find_request
      begin
        render :template => 'requests/show.builder'
      rescue Exception => e
        error_message(e.message)
      end
    else
      validation_request_error
    end
  end

  def list_servers
    # blahblah/REST/list_servers?token=ajkfhgag;ad295jaljk&environment=dev
    if !validate_token.nil?
      begin
        unless params[:environment].nil?
          requested_env = params[:environment]
          env = Environment.find_by_name(requested_env)
          if env.nil?
            @message = "No Environment found: #{requested_env}"
          @servers = []
          else
            @message = "Server list: from environment #{env}"
          @servers = env.servers.active
          end
        else
          @message = "Server list: from environment #{env}"
          @servers = Server.active
        end
        render :template => 'servers/show.builder'
      rescue Exception => e
        error_message(e.message)
      end
    else
      validation_request_error
    end
  end

  def get_request
    # blahblah/REST/requests/:id/get_request?token=ajkfhgag;ad295jaljk&complete=yes
    #conds = params[:send_inline_xml].present? ? find_request : !validate_token.nil? && find_request
    conds = params[:send_inline_xml].present? ? find_request : find_request
    if conds
      begin
        xml =  @request.to_xml( :include => [:apps, :environment]).gsub("</request>\n","")
        if (!@request.steps.nil? && !@request.steps.empty?)
          xml += @request.steps.to_xml(:include => [:script, :servers]).gsub("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n","")
        end
        xml += "</request>\n"
        if params[:send_inline_xml].present?
          send_data @request.as_xml, :type => 'text/xml', :filename => "#{@request.number}.xml"
        else
          render :xml => xml
        end
      rescue Exception => e
        if params[:send_inline_xml].present?
          flash[:error] = "Request export cannot be created"
        else
          error_message(e.message)
        end
      end
    else
      validation_request_error
    end
  end

  def create_request_xml
    if verify_xml_data
      template_name = (@post_data/"template_name").innerHTML
      unless template_name.empty?
        request_template = RequestTemplate.find_by_name(template_name)
        create_request_from_template_xml(request_template)
      else
        error_message("Request Template: #{template_name} not found")
      end
    else
      validation_error
    end
    render :template => 'requests/rest_post_data'
  end

  def create_request_from_template_xml(request_template)
    begin
      @message = "Creating Request from template: #{request_template} on #{Time.now.to_s}\n"
      request_params.each do |obj_name|
        params[obj_name.to_sym] = (@post_data/obj_name).innerHTML
      end
      @request = request_template.create_request_for(@rest_user, params)
      if @request
        @request.should_time_stitch = true
        #logger.info "SS Params #{current_user.inspect}, #{params.inspect}"
        if params[:request]
          params[:request].delete_if { |k, v| v.blank? }
          @request.attributes = params[:request]
        end
        @request.rescheduled = false # Rescheduled should be false for requests created from templates
        @request.save
        output_dir = AutomationCommon.get_output_dir('request', @request.steps[0])
        file_name = "#{output_dir[0..(output_dir.index(@request.number.to_s)+@request.number.to_s.length)]}xml_post_data.xml"
        xml_file = File.new(file_name, "w+")
      xml_file.print(@post_data)
      xml_file.close
      else
        @message += "No request template found"
      end
      unless (@post_data/"auto_start").innerHTML.empty?
        @message += ", Auto-Starting request"
        update_request_state("start")
        render :template => 'requests/show.builder'
      else
        @message += "Unable to create request from template "
      end
    rescue Exception => e
      error_message(e.message) #e.backtrace for details
    end
  end

  def validate_token
    @rest_user = User.current_user
  end

  def find_request
    @request = Request.find_by_number(params[:request_id].to_i) if params[:request_id]
    @request = Request.find_by_number(params[:id].to_i) if params[:id]
    
    #logger.info "Finding Request: #{params[:request_id]}, #{@request.inspect}"
    !@request.nil?
  end

  def find_step
    @step = Step.find(params[:step_id])
    !@step.nil?
  end

  def find_script(script_name)
    #logger.info "Finding Script: #{script_name}"
    script = CapistranoScript.find_by_name(script_name)
    script = BladelogicScript.find_by_name(script_name) if script.nil?
    script = Script.find_by_name(script_name) if script.nil?
    script
  end

  def validation_request_error
    render :xml => "<xml><error><response>Validation Failed and/or Request id: #{params[:request_id]} not found </response></error></xml>\n"
  end

  def validation_error
    render :xml => "<xml><error><response>Validation Failed</response></error></xml>", :status => :forbidden
    return
  end

  def general_error(message)
    render :xml => "<xml><error><response>#{message}</response></error></xml>\n", :status => :bad_request
  end

  def verify_xml_data
    result = false
    unless params["xml_data"].nil?
      # hpricot was removed and the compatible decorator for nokogiri used
      @post_data = Nokogiri::Hpricot::XML(params["xml_data"])
      token = (@post_data/"token").innerHTML
      params[:token] = token if params[:token].blank?
      found_user = validate_token
      result = true unless found_user.nil?
    end
    result
  end

  # This method can be used for
  # RequestsController#create_request_from_template
  # RestController#create_request_from_template

  # TODO - Talk to Brady and Piyush and make changes in
  # RequestsController#create_request_from_template
  def request_from_template
    current_user = validate_token
    if params[:request_template_id].blank?
      # dont do anything
      else
      @request_template = RequestTemplate.find(params[:request_template_id])
      @request_template.existing_request_id = params[:request][:id] if params[:request] && params[:request][:id]
      @request = @request_template.create_request_for(current_user, params)
    @request.should_time_stitch = true
    end
    if @request
      #logger.info "SS Params #{current_user.inspect}, #{params.inspect}"
      if params["request"].has_key?(:plan_id)
        cur_plan = params["request"][:plan_id]
        cur_plan_stage = params["request"][:plan_stage_id]
        params["request"].delete(:plan_id)
        params["request"].delete(:plan_stage_id)
      end
      #logger.info "SS Params #{current_user.inspect}, #{params.inspect}"
      if params[:request]
        params[:request].delete_if { |k, v| v.blank? }
        @request.attributes = params[:request]
      end
    @request.rescheduled = false # Rescheduled should be false for requests created from templates
    @request.save
    @request.turn_off_steps # Turn OFF steps whose components are not selected
    @request.set_commit_version_of_steps
    else
      @message += "No request template found"
    end
  end

  def update_request_state(transition = nil)
    @message = "REST Request to update state\n"
    @request = Request.find_by_number(params[:request_id]) if @request.nil?
    unless @request.nil?
      current_user = validate_token
      @request.state_changer = current_user
      transition = params[:transition].to_s if transition.nil?
      @message += "\tRequest: #{@request.name} - Current state: #{@request.aasm_state.to_s} going to: #{transition}.  "
      @transition_successful = case transition
      when 'plan'
        @request.plan_it!
      when 'start'
        @request.update_attribute :notify_on_request_start, false
        @request.plan_it! if @request.aasm_state.to_s == "created"
        @request.start_request!
        @request.steps.anytime_steps.collect { |s| s.ready_for_work! if s.should_execute? }
      when 'hold'
        @request.put_on_hold!
      when 'problem'
        @request.update_attributes params[:request] if params[:request]
        @request.add_log_comments :problem, params[:note]  if params[:note]
        @request.problem_encountered!
      when 'resolve'
        @request.update_attributes params[:request]  if params[:request]
        @request.add_log_comments :resolved, params[:note] if params[:note]
        @request.resolve!
      when 'cancel'
        @request.update_attributes params[:request]  if params[:request]
        @request.add_log_comments :cancelled, params[:note] if params[:note]
        @request.cancel!
      when 'reopen'
        @request.reopen!
      when 'finish'
        @request.should_finish?
      end

      # Recent-Activity code
      request_data = @request.name.blank? ? @request.number : @request.name
      req_link = request_link(@request.number)

      if @request.plan_member
        plan_name = @request.plan_member.try(:plan).try(:name)
        plan_stage = @request.plan_member.try(:stage).try(:name)
        message = ""
        message += "Plan #{plan_name} #{plan_stage} stage " if plan_name && plan_stage
        message +=  "#{@request.number.to_s} has been #{@request.aasm_state} for Application #{@request.app_name}"
        current_user.log_activity(:context => message) do
          @request.update_attributes(params[:request]) if params[:request]
        end
      elsif @request.promotion?
        message = "Promotion #{@request.number.to_s} has been #{@request.aasm_state} for Application #{@request.app_name}"
        current_user.log_activity(:context => message) do
          @request.update_attributes(params[:request]) if params[:request]
        end
      else
        message = "#{@request.number.to_s} has been #{@request.aasm_state} for Application #{@request.app_name}"
        current_user.log_activity(:context => message) do
          @request.update_attributes(params[:request]) if params[:request]
        end
      end
    @message += message
    else
      @message = "Cannot locate Request: #{params[:id]}"
    end
  end

  def error_message(message)
    builder = Builder::XmlMarkup.new
    xml = builder.tt { |t| t.information { |i|
        i.success(false)
        i.status(0)
        if message.class.to_s == 'Array'
          message.each {|m| i.exceptionMessage(m)}
        else
          i.errors {|i| i.error(message)}
        end
      }}
    render :xml => xml
  end

  def render_success_xml
    builder = Builder::XmlMarkup.new
    xml = builder.tt { |t| t.information { |i| i.success(true)}}
    render :xml => xml
  end


  
  private
  
  def render_xml_with_request_number(message)
    builder = Builder::XmlMarkup.new
    xml = builder.tt { |t|
      t.error(message)
      t.request_id(@request.number)
    }
    render :xml => xml
  end

end
