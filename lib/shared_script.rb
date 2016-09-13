################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module SharedScript
  EXIT_CODE_FAILURE = 'Exit_Code_Failure'

  include AutomationBackgroundable
  require 'net/http'
  require 'uri'
  require 'automation_common'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    include AutomationBackgroundable::ClassMethods

    def background_run(script_id, params)
      @script = self.find(script_id)
      @script.background_run(params)
    end

    def background_run_handler(step_id, error)
      AutomationQueueData.error_queue_data step_id, error
    end
  end

  def bladelogic?
    self.methods.include?('authentication')
  end

  def ssh?
    !bladelogic?
  end

  def capistrano
    !bladelogic?
  end

  def get_script_type
    if self.class.to_s == "BladelogicScript"
      "bladelogic"
    elsif self.automation_category == "General" && self.automation_type != "ResourceAutomation"
      "ssh"
    elsif self.automation_category == "Hudson/Jenkins" && self.automation_type != "ResourceAutomation"
      "hudson"
    elsif self.automation_category == "BMC Remedy 7.6.x" && self.automation_type != "ResourceAutomation"
      "remedy"
    elsif self.automation_type == "ResourceAutomation"
      "resource_automation"
    elsif self.automation_category == "BMC Application Automation 8.2" && self.automation_type != "ResourceAutomation"
      "baa"
    elsif self.automation_category == "RLM Deployment Engine" && self.automation_type != "ResourceAutomation"
      "rlm"
    elsif self.class.to_s == "Script"
      "script"
    end
  end

  def choose_run_script(params)
    case self.class.to_s
      when 'Script'
        run_automation_script(params)
      when 'BladelogicScript'
        run_bladelogic_script(params)
    end
  end

  def in_use_by
    self.steps.size - self.steps.used_in_deleted_requests.size
  end

  def fails_if_in_use
    if self.in_use_by > 0
      raise ActiveRecord::DeleteRestrictionError.new('step(s)')
    end
  end

  def clear_scripts_when_not_in_use
    self.steps.update_all('script_id = 0') if self.in_use_by == 0
  end

  def queue_run!(step, sync_content = 'false', execute_in_background = true)
    params = Hash.new
    params["SS_run_key"] = Time.now.localtime.to_i
    params["SS_script_type"] = "step"
    params["SS_script_target"] = get_script_type
    params["direct_execute"] = "yes" if direct_execute?
    params.merge!(AutomationCommon.build_params(params, step, self))
    params.merge!(AutomationCommon.build_server_params(step))
    params = AutomationCommon.encrypt_values(params)

    # If execute_in_background is true then script is not an Resource Automation
    if execute_in_background
      content = sync_content == "false" ? step.script.content : sync_content
    else
      content = sync_content == "false" ? self.content : sync_content
    end

    AutomationCommon.init_run_files(params, content)
    params["SS_context_root"] = ContextRoot::context_root

    if execute_in_background
      logger.info "SS__ Queueing background task Step: #{step.id.to_s} Script: #{step.script.name}, type: #{params["SS_script_target"]}"
    else
      logger.info "SS__ Queueing background task Step: #{step.try(:id).try(:to_s)} Script: #{self.name}, type: #{params["SS_script_target"]}"
    end

    return params unless execute_in_background

    if execute_in_background
      params['ignore_exit_codes'] = ignore_exit_codes_params_value(step) if ssh?
      self.class.background(error_handler_method: :background_run_handler, args: [step.id]).
          background_run(self.id, params)

      # to track jobs in queue on Automation Monitor tab
      AutomationQueueData.track_queue_data step.id
    end

    true
  end

  def background_run(params) # This step is run in a background process
    # Run the script
    User.current_user = User.find_by_login(params["request_login"])
    @step = Step.find(params["step_id"])

    return 'Attempt to run script on a completed step - Denied' if @step.complete?

    run_params = {
        "job_type" => "automation",
        "step_id" => @step.id,
        "script_id" => id,
        "user_id" => params["step_user_id"],
        "run_key" => params["SS_run_key"],
        "results_path" => params["SS_output_file"]
    }

    jr = JobRun.log_job(run_params)

    @request = @step.request
    tstamp = Time.now.localtime
    logger.info "=== Request: #{@request.id.to_s} - Step(#{@step.id.to_s}): #{@step.name} "
    script_result = choose_run_script(params)
    finish_time = Time.now.localtime
    jr.process_id = params["SS_process_pid"]
    jr.finished_at = finish_time
    jr.updated_at = finish_time
    jr.results_path = params["SS_output_file"]
    #AutomationCommon.append_output_file(params,script_result)
    logger.info "Finished: #{finish_time.to_s}"
    logger.info "--------  Output ---------\n#{script_result.slice(0..4000)}"
    # BJB 12-8-11 Add Job Run ID to the note
    @step.notes.create(content: "\nScript Results:\n#{script_result.split("\n").last(20).join("\n")}\n\n",
                       user_id: params['step_user_id'],
                       holder_type: 'JobRun',
                       holder_type_id: jr.id.to_s)

    # clear the queue data after notes written
    AutomationQueueData.clear_queue_data @step.id

    if AutomationCommon.error_in?(script_result)
      logger.info "Script encountered a problem - setting step status"
      @step.problem!
      @step.update_script_arguments_for_pack_response(script_result) unless @step.script.class.to_s == "BladelogicScript"
      jr.status = "Problem"
    else
      set_values_from_script(script_result)
      if params["SS_wait_for_signal"].nil?
        logger.info "Script successful - now completing step id##{@step.id}name##{@step.name}"
        jr.status = "Complete"
        # Adding method for updating the pack response
        @step.update_script_arguments_for_pack_response(script_result) unless @step.script.class.to_s == "BladelogicScript"

        @step.all_done!

        logger.error("Error: failed to switch automation Step##{@step.id} to `completed` state
                      from `#{@step.aasm_state}` after the script ran. Step => #{@step.inspect}") unless @step.complete?

      end
    end
    jr.save
    pre_info = "Step #{@step.position}: ID #{@step.id}:"
    if params["SS_wait_for_signal"].nil?
      message = "#{pre_info} Automation changed step from in-process to #{jr.status} - job run id: #{jr.id}"
    else
      message = "#{pre_info} Automation for staying in-process waiting for remote signal - job run id: #{jr.id}"
    end
    LogActivity::ActivityMessage.new(@step, params["step_user_id"].to_i).log_activity(message)

    script_result.slice(0..500)
  end

  def set_values_from_script(results)
    reg = /\$\$SS_Set_.+?\}\$\$/m
    title_reg = /SS_Set_.+\{/
    lists = results.scan(reg)
    #puts "Scan results: #{lists.inspect}"
    return if lists.empty?
    msg = "SS__ Setting values from script\n Found #{lists.size} entries\n"
    lists.each do |list_item|
      obj_name = list_item.scan(title_reg)[0].gsub("SS_Set_","").gsub("{","")
      if obj_name.present? && obj_name.length > 2
        msg += "SS__ List objects from script: #{obj_name}.\n"
        msg += process_script_list(obj_name, list_item)
      end
    end
    logger.info msg
    msg
  end

  def process_script_list(list_type, result)
    return if @step.nil?
    cols = []
    tmp = result.gsub("$$SS_Set_#{list_type}{","").gsub("}$$","")
    list = tmp.split("\n")
    msg = "SS_ Updating #{list_type} from script\n#{list.inspect}"
    #puts "Current List: #{list.inspect}"
    list.reject{ |k| (k.nil? || k.length < 2) }.each_with_index do |item, idx|
      cols = item.split(",").map{ |it| it.strip } if idx == 0
      # Now add records and associations
      if cols.length > 1 && idx > 0
        case list_type.downcase
          when 'servers'
            msg += set_server_value(item, cols)
          when 'components'
            msg += set_component_value(item, cols)
          when 'property'
            msg += set_property_value(item, cols)
          when 'properties'
            msg += set_property_value(item, cols)
          when 'application'
            msg += set_application_value(item, cols)
        end
      else
        case list_type.downcase
          when 'property'
            msg += set_property_value(item)
          when 'application'
            msg += set_application_value(item)
        end
      end
    end
    # logger.info msg
    msg
  end

  def set_property_value(item, cols = [])
    msg = ""
    prop_details = parse_set_row(item, cols) unless cols.empty?
    prop_details = make_value_hash(item) if cols.empty?
    prop_name = prop_details["name"]
    prop_value = prop_details["value"]
    return "#{msg}No value" if prop_value.nil? || prop_value.to_s.length < 1
    property = Property.find_by_name(prop_name)
    component = Component.find_by_name(prop_details["component"]) if prop_details.has_key?("component")
    env_id =  Environment.find_by_name(prop_details["environment"]).try(:id) if prop_details.has_key?("environment")
    is_private = false
    is_private = (prop_details["private"] == "true") if prop_details.has_key?("private")
    component = @step.component if component.nil?
    env_id = @step.request.environment_id if env_id.nil?
    logger.info "SS__ Setting: Prop: #{prop_name}, #{prop_value}, #{component.id.to_s}, #{env_id.to_s}\n#{item.inspect}"
    ic = InstalledComponent.find_by_app_comp_env(@step.app_id, component.id,env_id)
    if property.nil? && !ic.nil?
      msg += "Creating new property: #{prop_name}\n"
      property = Property.new(name: prop_details['name'], default_value: prop_details['value'], component_ids: [component.id])
      property.is_private = is_private
      property.save!
    else
      property.components << component unless property.components.map(&:id).include?(component.id)
    end
    msg += " #{prop_name}[#{property.inspect}]: change value from:  to #{prop_details.inspect}\n"
    if prop_details.has_key?("global") && (prop_details["global"].downcase == "true" || prop_details["global"].downcase == "yes")
      msg += "Forcing save to global property dictionary\n"
      @step.archive_property_value("installed_component", ic.id, property.id)
      property.update_value_for_installed_component(ic, prop_value)
    else
      msg += "Saving at local request level\n"
      @step.update_property_values!({"installed_component" => { ic.id.to_s => { property.id.to_s => prop_value }}})
    end
    msg
  end

  def set_server_value(row, cols)
    server_items = parse_set_row(row, cols)
    serv = server_items["name"].blank? ? nil : Server.find_or_create_by_name(server_items["name"])

    # Adding following code for supporting adding server groups
    server_group = ServerGroup.find_or_create_by_name(server_items["group"]) if server_items["group"]
    env = @step.request.environment
    env = Environment.find_by_name(server_items["environment"]) unless server_items["environment"].nil?
    unless env.nil?
      env.environment_servers.find_or_create_by_server_id(serv.id) if serv
      # also associate the server group with the environment so the application user interface shows selection
      env.server_groups << server_group unless server_group.blank? || env.server_groups.include?(server_group)
    end
    unless @step.installed_component.nil? || (env.id != @step.request.environment.id)
      @step.installed_component.servers << serv if !@step.installed_component.servers.map(&:id).include?(serv.id) && serv
    end
    if server_group.present? && serv
      serv.server_groups << server_group unless serv.server_groups.map(&:name).include?(server_group.name)
    end
    group_note = server_items["group"].nil? ? "" : ", Group: #{server_items["group"]}"
    "Server: #{server_items["name"]}, in env: #{server_items["environment"]}#{group_note}"
  end

  def set_component_value(row, cols)
    component_items = parse_set_row(row, cols)
    msg = ""
    app = App.find_or_create_by_name(component_items["application"]) unless component_items["application"].nil?
    app_id = app.nil? ? @step.app_id : app.id
    comp = Component.find_or_create_by_name(component_items["name"])
    env_id = Environment.find_or_create_by_name(component_items["environment"]).try(:id) unless component_items["environment"].nil?
    env_id = @step.request.environment_id if env_id.nil?
    app_comp = ApplicationComponent.find_or_create_by_app_id_and_component_id(@step.app_id, comp.id)
    app_env = ApplicationEnvironment.find_by_app_id_and_environment_id(@step.app_id, env_id)
    app_comp = ApplicationComponent.find_or_create_by_app_id_and_component_id(app_id, comp.id)
    app_env = ApplicationEnvironment.find_or_create_by_app_id_and_environment_id(app_id, env_id)
    if app_env.present?
      ic = InstalledComponent.find_or_create_by_application_component_id_and_application_environment_id(app_comp.id,app_env.id)
      ic.version = component_items["version"] unless component_items["version"].nil?
      ic.save
      msg += "Setting version to: #{component_items["version"].nil? ? "" : ic.version} on #{comp.name}"
    else
      msg += "Component: #{comp.name} is not present in the #{component_items["environment"]}"
    end
    msg
  end

  def set_application_value(application_items, cols = [])
    app_details = make_value_hash(application_items)
    msg = ""
    app = App.find_by_name(app_details["name"])
    app ||= @step.app
    # logger.info "SS__ Found App: #{app.name}, set version to: #{app_details["value"]}"
    if app.nil?
      msg += "Could not find app: #{app_details["name"]} or Component not set on step"
    else
      app.update_attributes(app_version: app_details['value'])
      msg += "Application: #{app_details["name"]}, set version: #{app_details["value"]}"
    end
    msg
  end

  # controllers were assembling these argument values, but really the model should own this
  def filter_argument_values
    argument_values = {}
    self.arguments.each do |arg|
      argument_values[arg.id] = { "value" => "" }
    end
    argument_values
  end

#============================ PRIVATE =============================
  private

  def parse_arguments
    arg_string = self.content.match(argument_regex)
    result = arg_string[1] if arg_string
    result.gsub! "\t", "  " if result
    result
  end

  def in_order_arguments
    parsed_args = parse_arguments

    if parsed_args
      parsed_arg_array = parsed_args.split(/\r?\n/)
      parsed_arg_array.reject! { |str| str.include?('  name:') || str.include?('  description:') || str.strip.blank? }
      parsed_arg_array.map! { |str| str.match(/\s*(\w+):/)[1] }
    end
    parsed_arg_array || []
  end

  def parsed_arguments
    parsed_args = parse_arguments
    if parsed_args
      yml = YAML.load(parsed_args)
      if yml.is_a? Hash
        return yml.stringify_keys
      else
        raise "The script header does not seem to be according to the format specified"
      end
    end
    {}
  end

  def check_content
    @content_changed = self.content_changed?
    true
  end

  def direct_execute?
    phrase = 'params["direct_execute"]'
    ipos = content.index(phrase)
    if ipos
      frag = content.slice((ipos + phrase.length)..(ipos + phrase.length)+ 8)
      !(frag.include?('false') || frag.include?('no'))
    else
      false
    end
  end

  def wait_for_signal?
    phrase = 'params["SS_wait_for_signal"]'
    ipos = content.index(phrase)
    if ipos
      frag = content.slice((ipos + phrase.length)..(ipos + phrase.length)+ 8)
      !(frag.include?('false') || frag.include?('no'))
    else
      false
    end
  end

  def update_arguments
    if @content_changed
      argument_hash = parsed_arguments    #> Changed from in_order_arguments

      (self.arguments.map { |arg| arg.argument } - argument_hash.keys).each do |removed_arg|    #> the primary keys of the yaml are the argument names
        self.arguments.find_by_argument(removed_arg).destroy
      end
      argument_hash.each do |arg, vals|   # Reuse the variable from above instead of calling parsed args
        if arg.length > 1
          new_arg_object = self.arguments.find_or_initialize_by_argument(arg)
          vals.keys.each do |key|
            if key.present?
              case key
                when "name"
                  new_arg_object.name = vals[key]
                when "description"
                  new_arg_object.name = vals[key]
                when "position"
                  new_arg_object.position = vals[key]
                when "type"
                  new_arg_object.argument_type = vals[key]
                when "required"
                  new_arg_object.is_required = vals[key]
                when "external_resource"
                  new_arg_object.external_resource = vals[key]
                when "list_pairs"
                  new_arg_object.list_pairs = vals[key]
              end
              if key.include?('choices') && vals[key].present? && new_arg_object.class.to_s == "BladelogicScriptArgument"
                res = vals[key].split(",")
                res = vals[key].split(";") if res.empty?
                new_arg_object.choices = res
              end
            end
            unless new_arg_object.class.to_s == "BladelogicScriptArgument"
              new_arg_object.is_required = false unless vals.keys.include?("required")
              new_arg_object.argument_type = "in-text" unless vals.keys.include?("type")
              new_arg_object.external_resource = nil unless vals.keys.include?("external_resource")
            end

          end if vals.respond_to?(:keys)
          # BJB add private flag
          parsed_arguments[arg]['private'].nil? ? new_arg_object.is_private = false : new_arg_object.is_private = true
          # logger.info "SS Saving argument: #{new_arg_object.inspect}"
          begin
            new_arg_object.save!
          rescue Exception => e
            read_error = "Unable to save Record due to error - #{e.message}"
            logger.info "#{read_error}"
          end
        end
      end
      self.arguments(true)
    end
  end

  def delete_content
    FileUtils.rm("#{default_path}/#{id}.script", force: true)
  end

  def fetch_url(path, testing=false)
    tmp = "#{path}".gsub(" ", "%20") #.gsub("&", "&amp;")
    jobUri = URI.parse(tmp)
    logger.info "Fetching: #{jobUri}"
    Net::HTTP.get(jobUri) unless testing
  end

  def make_value_hash(prop)
    return prop if prop.is_a?(Hash) # Multi-set capability
    set_props = Hash.new
    prop_details = prop.split(",")
    prop_details.each_with_index do |item, idx|
      pair = item.split("=>").map{|it| it.gsub("\"","").strip }
      if pair.size == 2
        if idx == 0
          set_props["name"] = pair[0]
          set_props["value"] = pair[1]
        else
          set_props[pair[0]] = pair[1]
        end
      end
    end
    set_props
  end

  def parse_set_row(row, cols)
    res = {}
    row.split(',').map{ |it| it.strip }.each_with_index do |it, cnt|
      res[cols[cnt]] = it
    end
    res
  end

  def ignore_exit_codes_params_value(step)
   ignore_exit_codes_script_argument(step)
  end

  def ignore_exit_codes_script_argument(step)
    script_argument = step.step_script_arguments
                          .includes(:script_argument)
                          .select { |a| a.script_argument.argument == 'ignore_exit_codes' }
                          .first
                          .try(:script_argument)
    if script_argument.present?
      argument = script_argument.step_script_arguments.find_by_step_id(step.id)
      argument.value.first
    else
      ''
    end
  end
end
