class Request < ActiveRecord::Base
  require 'xmlsimple'
  ALLOWED_IMPORT_FIELDS = %w(name description component assigned_to estimate automation)
  LOOKUP_FIELDS = {
    'owner-id' => 'User', 'business-process-id' => 'BusinessProcess', 'phase-id' => 'Phase', 'work-task-id' => 'WorkTask',
    'component-id' => 'Component', 'environment-id' => 'Environment', 'release-id' => 'Release',
    'requestor-id' => 'User', 'activity-id' => 'Activity', 'app-id' => 'App',
    'category-id' => 'Category', 'change-request-id' => 'ChangeRequest', 'deployment-coordinator-id' => 'User',
    'environment-group-id' => 'EnvironmentGroup' }
  attr_accessor :import_note

  class << self

    def import(xml, user)
      params = convert_xml_to_hash(xml)
      @request_note = "\nImport Request #{Time.now}\n"
      request_header = build_request_header(params)
      if request_header['app_ids'].blank? or request_header['environment_id'].blank?
        raise ArgumentError.new(I18n.t('request.import_request.error_app_env_blank'))
      else
        #begin
          @request = Request.new(request_header)
          if user.can?(:create, @request)
            @request.save(:validate => false)
            @request.import_note = ''
            @request.add_request_notes(params)
            @request.add_steps_to_imported_request(xml)
            @request.update_procedures
            @request.update_steps_exec_condition
            @request.description = @request_note + @request.import_note + "\n------ Original Description ------\n" + @request.description
            @request.save(:validate => false)
            # Return request number
            @request.number
          else
            raise ArgumentError.new(I18n.t('request.import_request.error_have_not_access_to_app_or_env'))
          end
        #rescue => err
        #  raise ArgumentError.new("Problems with the import data - field names do not match current database.")
        #end
      end
    end

    def build_request_header(params)
      # Build request params hash that can be used in Request.create(request_params)
      new_request_params = {}
      exclude_from_request = %w(id frozen_app frozen_business_process frozen_deployment_coordinator frozen_environment frozen_release frozen_requestor
                                notes created_from_template origin_request_template_id)
      request_env_id = Environment.find_by_name(params['environment-id'].first['content']).try(:id)
      if request_env_id.blank?
        request_env_id = Environment.find(params['environment-id'].first['content']).try(:id)
      end
      request_app_ids = find_request_apps(params)
      request_params = params.delete_if{|key, _| key == 'steps' || key == 'apps' || key == 'environment' || key == 'plan-member-id' }
      request_params.each {|key, val|
        new_request_params[key.gsub('-', '_')] = find_request_values(key,val)
      }

      new_request_params = new_request_params.delete_if {|key, _| exclude_from_request.include?(key)}
      new_request_params['app_ids'] = request_app_ids
      new_request_params['environment_id'] = request_env_id
      new_request_params['requestor_id'] = find_user(new_request_params['requestor_id'])[0]
      new_request_params['owner_id'] = find_user(new_request_params['owner_id'])[0]
      new_request_params['description'] = '' if new_request_params['description'].nil?
      new_request_params['aasm_state'] = 'created'
      new_request_params['completed_at'] = nil
      new_request_params['started_at'] = nil
      new_request_params['planned_at'] = nil
      new_request_params['business_process_id'] = find_id_param(new_request_params, 'business_process_id')
      new_request_params['activity_id'] = find_id_param(new_request_params, 'activity_id')
      new_request_params['category_id'] = find_id_param(new_request_params, 'category_id')
      new_request_params['deployment_coordinator_id'] = find_user(new_request_params['deployment_coordinator_id'])[0]
      new_request_params['estimate'] = convert_estimate(new_request_params['estimate']) if new_request_params['estimate'].present?
      if new_request_params['deployment_window_event_id'].present?
        dw_event = DeploymentWindow::Event.where(id: new_request_params['deployment_window_event_id']).first
        new_request_params['deployment_window_event_id'] = dw_event.try(:id)
      end
      new_request_params['release_id'] = find_id_param(new_request_params, 'release_id')

      # create a new plan member id for this request
      lm_id = new_request_params['plan_member_id']
      unless lm_id.blank?
        original_lm = PlanMember.find(lm_id) rescue nil
        if original_lm.present?
          new_lm = PlanMember.create(:plan_id => original_lm.plan_id, :plan_stage_id => original_lm.plan_stage_id, :run_id => original_lm.run_id)
          new_request_params['plan_member_id'] = new_lm.try(:id)
        else
          new_request_params['plan_member_id'] = nil
        end
      end

      new_request_params
    end

    def find_user(cur_user, cur_type = 'User')
      if cur_user.present?
        if cur_type == 'User'
          user = User.active.find_by_login(cur_user).try(:id)
          @request_note += ", Cannot find #{cur_user} by login" if user.nil?
          user = User.active.find_by_last_name(cur_user).try(:id) if user.nil?
          @request_note += ", Cannot find #{cur_user} by last_name" if user.nil?
        else # Group
          user = Group.active.find_by_name(cur_user).try(:id)
          cur_type = 'User' if user.nil?
          @request_note += ", Cannot find #{cur_user} by group_name" if user.nil?
        end
        @request_note += ', Defaulting to current user' if user.nil?
      end
      user = User.current_user.id if user.nil? && !User.current_user.nil?
      user = User.find_by_login('admin').try(:id) if user.nil?
      [user,cur_type]
    end

    def find_id_param(params, id_param)
      klass = id_param.gsub('_id', '').classify.gsub('BusinessProces', 'BusinessProcess').constantize
      result = klass.find_by_name(params[id_param]).try(:id)

      #Searching again within unarchived records.Searching twice to get correct alert/updates in the notes.
      if !result.nil? && klass.is_archival?
        result=klass.unarchived.find_by_name(params[id_param]).try(:id)
        archived_arg = true
      end
      archived_arg ||= false

      if result.nil? && !params[id_param].blank?
        if archived_arg
          @request_note+=",Cannot add archived #{params[id_param]} in #{id_param} "
        else
          @request_note += ", Cannot find #{params[id_param]} in #{id_param}"
        end
      end
      result
    end

    def convert_estimate(estimate)
      estimate_to_minutes = {
        '1 hour' => 60, '1/2 day' => 720, '1 day' => 1440,
        '2 days'=> 48*60, '1 week'=> 168*60, 'weeks'=> 504*60, 'months'=> 1440*60
      }
      estimate_to_minutes.has_key?(estimate) ? estimate_to_minutes[estimate] : estimate
    end
  end

  def add_steps_to_imported_request(xml)
    params = Request.convert_xml_to_hash(xml)
    @procedure_steps = {}
    steps_array = params['steps']
    if steps_array.present?
      steps_hash = steps_array.first
      # logger.info "SS_Import: #{steps_hash["step"].size} to do"
      steps_hash['step'].each do |step_params|
        logger.info "SS_Import: Step - \n#{step_params.inspect}\n##########################\n"
        exec_cond_prms = step_params['execution-condition']
        new_step_params = build_step(step_params)
        is_procedure = new_step_params['original_id'].present? ? new_step_params['original_id'].to_i : -1
        new_step_params.delete('original_id')
        if new_step_params['component_id'].to_i > 0
          comp_id = new_step_params['component_id'].to_i
          self.apps.first.application_components.find_or_create_by_component_id(comp_id)
          InstalledComponent.create_or_find_for_app_component(self.apps.first.id, comp_id, self.environment_id)
        end
        @step = self.steps.build(new_step_params)
        @step.save!
        if step_params['servers'].first['server'].present?
          server_ids = []
          step_params['servers'].first['server'].each do |server|
            server_id = build_server(server)
            server_ids << server_id
          end
          @step.update_attribute(:server_ids, server_ids)
        end
        if @step.errors.empty?
          build_execution_condition(@step,exec_cond_prms)
        end
        @procedure_steps[is_procedure] = @step.id if is_procedure > 0
      end
    end
  end

  def build_step(params)
    exclude_from_step = %w(id frozen_owner frozen_automation_script frozen_bladelogic_script frozen_work_task
                           procedure script frozen_component servers server_aspects component execution_condition)
    new_step_hash = {}
    params.each { |key, value|
      new_step_hash[key.gsub('-', '_')] = find_step_values(key,value)
    }
    new_step_hash['original_id'] = new_step_hash['id'] if new_step_hash['procedure'] == 'true'
    new_step_hash = new_step_hash.delete_if {|key, _| exclude_from_step.include?(key)}
    owner_type = new_step_hash['owner_type'].blank? ? 'User' : new_step_hash['owner_type']
    user_arr = Request.find_user(new_step_hash['owner_id'], owner_type)
    new_step_hash['owner_id'] = user_arr[0]
    new_step_hash['owner_type'] = user_arr[1]
    new_step_hash['aasm_state'] = 'locked'
    new_step_hash['work_finished_at'] = nil
    new_step_hash['work_started_at'] = nil
    new_step_hash['app_id'] = app_ids[0]
    new_step_hash['component_version'] = '' if new_step_hash['component_version'].is_a?(Hash)
    new_step_hash['component_id'] = build_component(new_step_hash['component_id'])
    new_step_hash['description'] = '' if new_step_hash['description'].nil?
    new_step_hash['category_id'] = Request.find_id_param(new_step_hash, 'category_id')
    new_step_hash['change_request_id'] = ChangeRequest.find_by_short_description(new_step_hash['change_request_id'])
    new_step_hash['work_task_id'] = Request.find_id_param(new_step_hash, 'work_task_id')
    new_step_hash['phase_id'] = Request.find_id_param(new_step_hash, 'phase_id')
    new_step_hash['runtime_phase_id'] = new_step_hash['runtime_phase_id'] if new_step_hash['phase_id'].present?
    new_step_hash['installed_component_id'] = InstalledComponent.find_by_app_comp_env(app_ids[0], new_step_hash['component_id'].to_i, environment_id)
    if new_step_hash['script_id'].to_i > 0 && !new_step_hash['installed_component_id'].nil?
      # BJB Temporarily remove scripts
      new_step_hash['script_id'] = build_script(params['script'].first,new_step_hash['script_type'])
      if new_step_hash['script_id'].blank?
        new_step_hash['script_id'] = nil
        new_step_hash['script_type'] = nil
        new_step_hash['manual'] = true
      end
    else
      new_step_hash['script_id'] = nil
      new_step_hash['script_type'] = nil
      new_step_hash['manual'] = true
    end
    # logger.info "SS__ Import: step: #{new_step_hash.inspect}"
    new_step_hash
  end

  def build_script(raw_params, script_type)
    script_params = {}
    raw_params.each{|k,v| script_params[k.gsub('-', '_')] = find_step_values(k,v) }
    script_type = if List.get_list_items('AutomationCategory').include?(script_type)
      automation_category = script_type
      'Script'
    else
      script_type
    end
    script = script_type.constantize.find_or_initialize_by_name(script_params['name'])
    if script.new_record?
      self.import_note += ",Creating new script: #{script_params['name']}"
      # logger.info "SS__ Import - Starting New Script"
      script.content = raw_params['content']
      if script_type == 'Script'
        script.automation_category = automation_category
        script.automation_type = 'Automation'
      else
        # This will be for BladelogicScripts
        script.script_type = script_type
      end
      script.description = script_params['description']
      script.save
    end
    script.id
  end

  def build_server(raw_params)
    server_params = {}
    raw_params.each{|k,v| server_params[k.gsub('-', '_')] = find_step_values(k,v) }
    server = Server.find_or_initialize_by_name(server_params['name'])
    if server.new_record?
      self.import_note += ", Creating new server: #{server_params['name']}"
      server.active = true
      server.dns = server_params['dns']
      server.ip_address = server_params['ip_address']
      server.os_platform = server_params['os_platform']
      server.environment_ids = [environment_id]
      server.save
    end
    server.id
  end

  def build_component(comp_name)
    return nil if comp_name.blank?
    component = Component.active.find_or_initialize_by_name(comp_name)
    if component.new_record?
      self.import_note += ", Creating new component: #{comp_name}"
      component.active = true
      component.save
    end
    component.id
  end

  def build_execution_condition(step,exec_cond_params)
    unless exec_cond_params.blank?
      exec_cond_params_hash = {}
       exec_cond_params[0].each { |key, value|
          exec_cond_params_hash[key.gsub('-', '_')] = find_step_values(key,value)
        }
      condition_type = exec_cond_params_hash['condition_type']
      exec_cond_params_hash['environment_ids'] = exec_cond_params_hash['environments'] if condition_type == 'environments'
      exec_cond_params_hash['environment_type_ids'] = exec_cond_params_hash['environment_types'] if condition_type == 'environment_types'
      exec_cond_params_hash = exec_cond_params_hash.delete_if {|key, _| %w(id created_at updated_at step_id environments environment_types).include?(key)}
      step.create_execution_condition(exec_cond_params_hash) if exec_cond_params_hash.present?
    end
  end

  def update_steps_exec_condition
    steps.includes(:execution_condition, :parent).each do |step|
      if step.execution_condition
        step_number = step.execution_condition.referenced_step.try(:number)
        if step_number
          new_step = steps.all.select {|s| s.number == step_number}.first
          step.execution_condition.referenced_step = new_step
          step.execution_condition.save
        end
      end
    end
  end

  def update_procedures
    proc_ids = @procedure_steps.map{ |_, v| v }
    steps.each do |cur|
      cur.parent_id = @procedure_steps[cur.parent_id] unless cur.parent_id.nil?
      cur.procedure = true if proc_ids.include?(cur.id)
      cur.save if proc_ids.include?(cur.id) || !cur.parent_id.nil?
    end
  end

  def self.convert_xml_to_hash(xml)
    XmlSimple.xml_in(xml)
    #returns hash
  end

  def self.find_request_apps(params)
    app_names = []
    app_ids = []
    if params['apps'].present?
      apps_hash = params['apps'].first
      apps_hash['app'].each do |app|
        app_names << app['name']
      end if apps_hash['app'].present?
      app_ids = App.find_all_by_name(app_names.flatten).map(&:id)
    end
    app_ids
  end

  def add_request_notes(params)
    return if params['notes'].blank?
    notes_hash = params['notes'].first
    if notes_hash['note'].present?
      notes_hash['note'].each do |note|
        note = Note.find(note['id'].first['content'].to_i)
        notes.create(:user_id => note.user_id, :content => note.content, :created_at => note.created_at)
      end
    end
  end

  def self.find_environment(params)
    if params['environment'].present?
      env = params['environment'].first
      env_name = env['name']
      env_id = Environment.find_by_name(env_name).try(:id)
      env_id
    end
  end

  def find_step_values(key,value)
    changed_key = key.gsub('-', '_')
    if (changed_key == 'script_type' && value.first.is_a?(String) ) || changed_key == 'name'
      value.first['nil'] == 'true' ? nil : value.first
    elsif (changed_key == 'environments') || (changed_key == 'environment_types')
      ids = []
      value.first[key[0..-2]].each { |env|
        ids << env['id'][0]['content']
      } if value.first[key[0..-2]].present?
      ids
    else
      value.first['content'].nil? ? value.first.kind_of?(String) ? value.first : value.first['content'] : value.first['content']
    end
  end

  def self.find_request_values(key,value)
    if key.gsub('-', '_') == 'name'
      value.first['nil'] == 'true' ? nil : value.first
    else
      value.first['content'].nil? ? value.first.kind_of?(String) ? value.first : value.first['content'] : value.first['content']
    end
  end

  def import_steps(paste_data)
    return_message = ''; name_found = false; lines = []
    if %w(created planned hold).include?(aasm_state)

      begin
        lines = CSV.parse(paste_data.gsub("\t", ','))
      rescue Exception => err
        return_message += err.message
        return return_message
      end
      #logger.info "SS__ Import: #{paste_data}\nLines: #{lines.inspect}"
      num_items = lines.size

      if num_items > 1
        line1_items = lines[0].size
        line2_items = lines[1].size

        if line1_items == line2_items
          field_map = {}
          lines[0].each_with_index do |title, idx|
            field_title = title.downcase.strip
            if ALLOWED_IMPORT_FIELDS.include?(field_title)
              name_found = true if field_title == 'name'
              field_map[idx] = field_title
            else
              field_map[idx] = 'ignored'
              return_message += "#{field_title} - (ignored),"
            end
          end
        else
          return_message += 'Inconsistent titles and data'
        end
      else
        return_message += 'Inconsistent titles and data'
      end
      user_found = true
      if name_found
        start_pos = steps.map(&:position).max || 0
        lines[1..-1].each do |line|
          step_params = {}
          step_params['position'] = start_pos += 1
          line.each_with_index do |item, idx|
            step_params[field_map[idx]] = item.is_a?(String) ? item.strip_quotes.strip : item unless field_map[idx] == 'ignored'
          end
          user_found = false if resolve_person(step_params['assigned_to'])[:owner].nil?
          add_step(step_params)
        end
        return_message += (field_map.has_value?('assigned_to') ? 'For at least one step, assigned_to not found. ' : '') + "Step assigned to #{user.name}" unless user_found
        return_message += " Success: #{num_items - 1} steps imported"
      end
    else
      return_message += 'Request must be in a design state'
    end
    return_message
  end

  def as_export_xml
    exclude_fields_request = [:frozen_app, :frozen_business_process, :frozen_deployment_coordinator, :frozen_environment, :frozen_release,
      :frozen_requestor, :plan_member_id]
    exclude_fields_step = [:frozen_component, :frozen_owner, :frozen_automation_script, :frozen_bladelogic_script, :frozen_app, :frozen_work_task, :package_template_properties]
    xml =  to_xml( :include => [:apps, :notes], :except => exclude_fields_request).gsub("</request>\n", '')
    if steps.present?
      xml += ordered_steps.to_xml( include: [:component, :script, :servers,
                                              execution_condition: { include: [ :environments, :environment_types ]
                                              }],
                                   except: exclude_fields_step).gsub("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", '')
    end
    xml = xml_substitute_ids(xml)
    xml += "</request>\n"
    xml
  end

  def xml_substitute_ids(xml)
    type_reg = />.*<\/owner-type>/
    LOOKUP_FIELDS.each do |field, klass|
      reg = />.*<\/#{field}>/
      orig_klass = klass
      found = xml.scan(reg)
      if field == 'owner-id'
        found_types = xml.scan(type_reg)
        found_types.insert(0, 'User')
      end
      found.each_with_index do |item, idx|
        id_val = item.gsub("</#{field}>", '').gsub('>', '').to_i
        if id_val > 0
          name_field = (klass == 'User' ? :login : (klass == 'ChangeRequest' ? :short_description : :name))
          if field == 'owner-id' && found_types[idx].include?('Group')
            klass = 'Group'
            name_field = :name
          else
            klass = orig_klass
          end
          name_val = klass.constantize.find_by_id(id_val).try(name_field)
          #xml.gsub!("#{id_val.to_s}</#{field}>", "#{name_val}</#{field}>") if name_val
          xml.gsub!(">#{id_val.to_s}</#{field}>", ">#{name_val}</#{field}>") if name_val
        end
      end
    end
    xml
  end

  def add_step(step_params)
    app_id = app_ids[0]
    comp_id = step_params['component'].nil? ? nil : Component.find_by_name(step_params['component']).try(:id)
    unless comp_id.nil? || app_id.nil?
      app_env = ApplicationEnvironment.find_by_app_id_and_environment_id(app_id, environment.id)
      app_comp = ApplicationComponent.find_by_app_id_and_component_id(app_id,comp_id)
      comp_id = nil if app_comp.nil?
      ic = InstalledComponent.find_by_application_component_id_and_application_environment_id(app_comp.id, app_env.id) unless app_comp.nil?
    end
    script = Script.find_script(step_params['automation'])
    user_search = resolve_person(step_params['assigned_to'])
    #logger.info "SS__ ImportCreateStep: user: #{user_search.inspect}, script: #{script.inspect}\n#{step_params.inspect}"
    new_step = self.steps.build({'name' => step_params['name']})
    new_step.component_id = comp_id unless ic.nil?
    new_step.installed_component_id = ic.nil? ? nil : ic.id
    new_step.description = step_params['description'].nil? ? '' : step_params['description']
    new_step.owner_id = user_search[:owner].nil? ? user_id : user_search[:owner].id
    new_step.owner_type = user_search[:owner_type].nil? ? 'User' : user_search[:owner_type]
    new_step.position = step_params['position']
    new_step.script_id = script.nil? ? nil : script.id unless ic.nil?
    new_step.script_type = script.nil? ? nil : script.try(:automation_category) unless ic.nil?
    new_step.manual = (script.nil? || ic.nil?)
    new_step.estimate = step_params['estimate'].nil? ? 5 : resolve_duration(step_params['estimate'])
    new_step.app_id = app_id
    # logger.info "SS__ ImportStep: #{new_step.inspect}"
    new_step.save!
  end

  def resolve_duration(time_or_int)
    result = 0
    result = time_or_int.to_i if time_or_int.to_i > 1
    if time_or_int.include?(':')
      parts = time_or_int.split(':')
      result = parts[0].to_i * 60 + parts[1].to_i
    end
    result
  end

  def resolve_person(user_or_group)
    result = {
      :message => 'no data',
      :owner_type => nil,
      :owner => nil
    }
    return result if user_or_group.nil?
    found = User.find_by_any(user_or_group)
    found_class = found.class.to_s
    case found_class
      when 'User'
        result[:message] = 'success, found user'
        result[:owner_type] = 'User'
        result[:owner] = found
      when 'Group'
        result[:message] = 'success, found group'
        result[:owner_type] = 'Group'
        result[:owner] = found
      when 'String'
        result[:message] = found
    end
    result
  end

end
