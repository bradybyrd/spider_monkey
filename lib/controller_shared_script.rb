################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ControllerSharedScript

  def index
    template = use_template
    template = 'automation_scripts' if use_template.nil? && params[:controller] == 'scripts'
    redirect_to controller: 'account', action: template
  end

  def new
    authorize! :create, :automation
    @script = associated_model.new
    render_new
  end

  def create
    authorize! :create, :automation
    @script = associated_model.new(params[:script])

    if @script.save
      request.xhr? ? ajax_redirect(index_path) : redirect_to(index_path)
    else
      @scripts = paginate_records(associated_model.all, params, 10)
      request.xhr? ? show_validation_errors(:script, {div: "#{@script.class.to_s.underscore}_error_messages"}) : render_new
    end
  end

  def edit
    authorize! :edit, :automation
    @script = find_script
    @script.update_bladelogic_arguments if bladelogic?
    @store_url = true
    render_edit
  end

  def update
    authorize! :edit, :automation
    @script = find_script
    if @script.update_attributes(params[:script])
      if request.xhr? && params[:do_not_render].blank?
        if params[:script][:script_type] == "BladelogicScript"
          render :template => "shared_scripts/bladelogic/update"
        else
          render :template => "shared_scripts/update"
        end
      else
        redirect_to(index_path)
      end
    else
      @scripts = paginate_records(associated_model.all, params, 10)
      request.xhr? ? show_validation_errors(:script, {:div => "#{@script.class.to_s.underscore}_error_messages"}) : render_edit
    end
  end

  def destroy
    authorize! :delete, :automation
    @script = find_script
    begin
      if @script.class.to_s == "BladelogicScript"
        @script.destroy
      else
        if @script.automation_type == "ResourceAutomation"
          if ScriptArgument.find_all_by_external_resource(@script.unique_identifier).length > 0
            flash[:error] = "Can't delete Resource Automation script as this script is being used in Automation script(s)."
          else
            @script.destroy
          end
        else
          @script.destroy
        end
      end
    rescue ActiveRecord::DeleteRestrictionError => e
      flash[:error] = "#{e.message}"
    end
    redirect_to(index_path)
  end

  def import_select_script
    render template: 'shared_scripts/import', layout: false
  end

  def import
    render template: 'shared_scripts/import', layout: false
  end

  #import from the library directory
  def import_local_scripts_list
    #set the basedir for scripts -- should probably be a configuration CONSTANT
    basedir = AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH

    # grab the directory to start in if passed
    @integration_server = params[:integration_server]
    @folder = params[:folder]
    @sub_folder = params[:sub_folder]
    script_files = []
    if @folder.present? && %w(bladelogic automation resource_automation).include?(@folder)
      if @sub_folder
        basedir = File.join(basedir, @folder, @sub_folder)
      else
        basedir = File.join(basedir, @folder)
      end

      # grab the file names split from subdirectories relative to that basedir for tree populating
      if File.directory?(basedir)
        script_files = Dir.chdir(basedir) { Dir.glob(File.join('**', '*.*')).map { |f| File.split(f) } }
        script_files = only_not_imported_scripts(script_files) if script_files.present?
      end
    else
      flash[:notice] = 'Missing or invalid script type.'
    end
    # send back an html snippet
    render template: 'shared_scripts/import_local_scripts_list', locals: { script_files: script_files.try(:sort), basedir: basedir }, layout: false
  end

  def import_automation_scripts
    authorize! :import, :automation
    render template: 'shared_scripts/import_automation_scripts', layout: false
  end

  def render_automation_types
    automation_type = params[:automation_type]
    automation_types = [["Select", ""]]
    List.get_list_items("AutomationCategory").each do |type|
      if type == "Hudson/Jenkins"
        automation_types << [type, "Hudson"]
      else
        automation_types << [type, type]
      end
    end
    if ["automation", "resource_automation"].include?(automation_type)
      render :text => ApplicationController.helpers.options_for_select(automation_types)
    end
  end

  def import_local_scripts
    authorize! :import, :automation

    script_files = params[:selected_scripts]
    project_server_id = params[:project_server_id].present? ? params[:project_server_id]  : nil
    folder = params[:folder] if ['bladelogic', 'automation', 'resource_automation'].include?(params[:folder])
    sub_folder = params[:sub_folder]
    logger.info("importing folder" + folder)
    error_messages = []
    success, error_messages = self.import_from_library(script_files, folder, sub_folder, project_server_id)
    redirect = true
    unless success
      if request.xhr?
        @validation_errors = error_messages
        @div = 'error_messages'
        @div_content  = render_to_string(template: 'misc/ajax_error_message_body', layout: false, locals: {
                                             options: {
                                                 title:   'Import operation encountered following errors',
                                                 errors:  @validation_errors }
        })
        render template: 'misc/update_div', formats: [:js], handlers: [:erb], content_type: 'application/javascript'
        redirect = false
      else
        flash[:error] = "Error importing scripts."
      end
    end

    if redirect == true
      redirect_path = case folder
      when 'bladelogic' then bladelogic_path
      else automation_scripts_path
      end

      if request.xhr?
        ajax_redirect(redirect_path)
      else
        redirect_to redirect_path
      end
    end
  end

  # show a plain text preview in a new window
  def import_local_scripts_preview
    @path = params[:path]
    unless @path.nil?
    @content ||= File.open(@path).read
    else
    @content = "Script not found at #{@path}"
    end
    render template: 'shared_scripts/import_local_scripts_preview', locals: {content: @content}, layout: false
  end

  def import_scripts_list
    #import from another streamstep server
    int_id = params[:integration_id].to_i
    integration = ProjectServer.find(int_id)
    return "No Integration with id #{int_id.to_s}" if integration.nil?
    script_list = Script.import_script_list(int_id)
    render template: 'shared_scripts/import_script_list', locals: {scripts: script_list}, layout: false
  end

  def test_run
    authorize! :test, :automation
    @script = find_script
    if @script.arguments.blank? || params[:argument]
      @result = @script.test_run!(params) #[:argument] || {})
      if @script.class.to_s == "BladelogicScript"
        render template: 'shared_scripts/bladelogic/test_run', layout: false
      else
        render template: 'shared_scripts/test_run', layout: false
      end
    else
      if @script.class.to_s == "BladelogicScript"
        render template: 'shared_scripts/bladelogic/add_arguments', locals: {argument_values: test_argument_values(@script)}, layout: false
      else
        render template: 'shared_scripts/add_arguments', locals: {argument_values: test_argument_values(@script)}, layout: false
      end
    end
  end

  def map_properties_to_argument
    @script = find_script
    @argument = @script.arguments.find(params[:script_argument_id])
    @selected_application_environment_ids = []
    @selected_property_ids = @argument.app_mapping_property_ids.uniq
    @selected_component_ids = @argument.app_mapping_component_ids.uniq
    @application_environment_ids = @argument.app_mapping_application_environment_ids.uniq
    @application_environment_rows = ApplicationEnvironment.find(@application_environment_ids)
    @selected_application_environment_ids = @application_environment_rows.map { |ae| ae.id.to_s }
    #FIXME: This statement does not do anything and should use Array() if it plans to convert this
    # or guarantee that it is an array
    @selected_application_environment_ids.to_a
    @selected_app_ids = @argument.app_mapping_app_ids
    @selected_server_property_ids = @argument.infrastructure_mapping_property_ids
    @selected_server_ids = @argument.infrastructure_mapping_server_ids
    @selected_server_aspect_ids = @argument.infrastructure_mapping_server_aspect_ids
    @server_level_id = ServerAspect.find_by_id(@selected_server_aspect_ids).server_level_id if @selected_server_aspect_ids.present?
    if @script.class.to_s == "BladelogicScript"
      render template: 'shared_scripts/bladelogic/map_properties_to_argument', layout: false
    else
      render template: 'shared_scripts/map_properties_to_argument', layout: false
    end

  end

  def update_argument_properties
    @script = find_script
    @argument = @script.arguments.find(params[:script_argument_id])
    if params[:application_environment_ids].to_s.include?("_")
      environment_ids, application_environment_ids = [],[]
      environment_ids << params[:application_environment_ids].select{|ids| ids.include?("_")}.collect {|x| x.split("_").first}
      environment_ids = environment_ids.flatten.compact
      application_environment_ids << params[:application_environment_ids].reject{|ids| ids.include?("_")}.collect{|x| x}
    application_environment_ids = application_environment_ids.flatten.compact
    application_environment_ids << ApplicationEnvironment.find_all_by_environment_id_and_app_id(environment_ids,params[:app_ids]).map(&:id)
    application_environment_ids.flatten!
    else
    application_environment_ids = params[:application_environment_ids]
    end
    application_component_ids = ApplicationComponent.find_all_by_app_id_and_component_id(params[:app_ids], params[:component_ids]).map { |app_env| app_env.id }
    installed_components = InstalledComponent.find_all_by_application_environment_id_and_application_component_id(application_environment_ids, application_component_ids)
    properties = Property.find_all_by_id(params[:property_ids])
    @argument.update_script_argument_to_property_maps(properties, installed_components)
    render partial: 'shared_scripts/parsed_parameters', locals: {script: @script}, layout: false
  end

  def update_argument_server_properties
    @script = find_script
    @argument = @script.arguments.find(params[:script_argument_id])

    servers = find_servers
    properties = Property.find_all_by_id(params[:property_ids])

    @argument.update_script_argument_to_property_maps(properties, servers)

    render partial: 'shared_scripts/parsed_parameters', locals: {script: @script}, layout: false
  end

  def multiple_application_environment_options
    app_ids = params[:app_ids]
    app_ids = [app_ids].flatten
    unless app_ids.blank?
      options = ""
      App.where(:id => app_ids).order('apps.name asc').each do |app|
        apply_method = current_user.has_global_access? ? nil : "app_environments_visible_to_user"
        options += "<optgroup class='app' label='#{app.name}'>"
        options += options_from_model_association(app, :application_environments, :apply_method => apply_method)
        options += "</optgroup>"
      end
    render text: options
    else
    render nothing: true
    end
  end

  def component_options
    if params[:application_environment_ids].to_s.include?("_")
      environment_ids, application_environment_ids = [],[]
      environment_ids << params[:application_environment_ids].select{|ids| ids.include?("_")}.collect {|x| x.split("_").first}
      environment_ids = environment_ids.flatten.compact
      application_environment_ids << params[:application_environment_ids].reject{|ids| ids.include?("_")}.collect{|x| x}
    application_environment_ids = application_environment_ids.flatten.compact
    application_environment_ids << ApplicationEnvironment.find_all_by_environment_id_and_app_id(environment_ids,params[:app_ids]).map(&:id)
    application_environment_ids.flatten!
    else
    application_environment_ids = params[:application_environment_ids]
    end
    application_component_ids = ApplicationComponent.find_all_by_app_id(params[:app_ids]).map { |app_comp| app_comp.id }
    installed_components = InstalledComponent.find_all_by_application_environment_id_and_application_component_id(application_environment_ids, application_component_ids)
    components = installed_components.map { |inst_comp| inst_comp.component }.uniq
    render text: ApplicationController.helpers.options_from_collection_for_select(components.sort_by(&:name), :id, :name)
  end

  def property_options
    component_properties = ComponentProperty.find_all_by_component_id(params[:component_ids])
    properties = component_properties.map { |comp_prop| comp_prop.active_property }.compact.uniq.sort_by{ |it| it["name"] }
    render text: ApplicationController.helpers.options_from_collection_for_select(properties, :id, :name)
  end

  def app_env_remote_options
    if params[:app_id].nil? || params[:app_id] == ''
    render text: ""
    else
    app = App.find_by_id(params[:app_id])
    render text: options_from_model_association(app, :application_environments, :named_scope => [:in_order, :with_installed_components])
    end
  end

  def package_remote_options
    if params[:app_env_id].nil?
      render text: ""
    else
      app_env = ApplicationEnvironment.find_by_id(params[:app_env_id])
      render text: options_from_model_association(app_env.app, :packages)
    end
  end

  def package_instance_remote_options
    if params[:package_id].nil?
      render text: ""
    else
      package = Package.find_by_id(params[:package_id])
      render text: ApplicationController.helpers.options_for_select([["Select", ""]]) +
          options_from_model_association(package, :package_instances)

    end
  end

  def installed_component_remote_options
    if params[:app_env_id].nil?
    render text: ""
    else
    app_env = ApplicationEnvironment.find_by_id(params[:app_env_id])
    render text: options_from_model_association(app_env, :installed_components)
    end
  end

  def default_values_from_properties
    unless params[:installed_component_id].nil?
      installed_component = InstalledComponent.find_by_id(params[:installed_component_id])
    else
      installed_component = nil
    end
    script = find_script
    if script.class.to_s == "BladelogicScript"
      render partial: 'steps/bladelogic/step_script', locals: {script: script, installed_component: installed_component, step: nil, argument_values: test_argument_values(script, installed_component)}
    else
      render partial: 'steps/step_script', locals: {script: script, installed_component: installed_component, step: nil, argument_values: test_argument_values(script, installed_component)}
    end
  end

  def default_values_from_server_properties
    server = find_server
    script = find_script

    argument_values = {}
    script.arguments.map(&:id).each do |arg|
      argument_values[arg] = ""
    end
    if script.class.to_s == "BladelogicScript"
      render :partial => 'steps/bladelogic/step_script', :locals => { :script => script, :installed_component => server, :step => nil, :argument_values => argument_values }
    else
      render partial: 'steps/step_script', locals: {script: script, installed_component: server, step: nil, argument_values: argument_values}
    end
  end

  def server_property_options
    servers = find_servers
    properties = servers.map { |s| s.properties }.flatten.uniq.sort_by(&:name)
    render text: ApplicationController.helpers.options_from_collection_for_select(properties, :id, :name)
  end

  def build_script_list # called from JS on automation type popup
    if params["script_class"] == "BladelogicScript"
      scripts = params["script_class"].constantize.order('name asc')
    else
      scripts = Script.unarchived.visible.where("scripts.automation_category = ? AND scripts.automation_type != ?", params["script_class"], 'ResourceAutomation').order('name asc')
    end
    render text: "<option value=''>Choose Script</option>" + ApplicationController.helpers.options_from_collection_for_select(scripts, :id, :name).html_safe
  end

  def get_remote_script_list
    # params[:integration_id]
    #choose integration type = Streamstep Federation
    # REST call get scripts list
    # nokogiri process xml to pick list
    # render form
  end

  def get_remote_scripts
    # params.each
    #   [:script_id]
    #   fetch script REST
    #   check name unique - munge
    #   create script/save
    # end
    #
  end

  def update_from_file
    @script = find_script
    @script.file_path = params[:file_path]
    if @script.test_file_path
      render text: File.open(@script.file_path).read
    else
      render text: "Can't find script in path."
    end
  end
  
  def update_to_file
    @script = find_script
    @script.file_path = params[:file_path]
    @script.content = params[:content]
    if @script.test_file_path(true)
      fil = File.open(@script.file_path, "w+")
      fil.write(@script.content)
      fil.flush
      fil.close
      render text: "Success"
    else
      render text: "Can't find script in path."
    end
    
  end
  
  protected

  def find_script
    associated_model.find params[:id]
  end

  def find_servers
    if params[:server_ids]
      Server.find_all_by_id(params[:server_ids])
    else
      sa_id = params[:server_aspect_ids].nil? ? -1 : params[:server_aspect_ids]
      ServerAspect.find_all_by_id(sa_id)
    end
  end

  def find_server
    if params[:server_id]
    Server.find_by_id(params[:server_id])
    else
    ServerAspect.find_by_id(params[:server_aspect_id])
    end
  end

  def associated_model
    @model ||= if bladelogic?
      BladelogicScript
    else
      Script
    end
    # @model ||= if bladelogic?
    # BladelogicScript
    # elsif capistrano?
    # CapistranoScript
    # else
    # HudsonScript
    # end
  end

  def index_path
    if bladelogic?
      bladelogic_path(:page => params[:page], :key => params[:key])
    else
      automation_scripts_path(:page => params[:page], :key => params[:key])
    end
    # if bladelogic?
    # bladelogic_path(:page => params[:page], :key => params[:key])
    # elsif capistrano?
    # capistrano_path(:page => params[:page], :key => params[:key])
    # else
    # hudson_path(:page => params[:page], :key => params[:key])
    # end
  end

  def test_argument_values(script, installed_component = nil)
    argument_values = {}
    script.arguments.each do |arg|
      if installed_component.nil?
        argument_values[arg.id] = { "value" => "" }
      else
        argument_values[arg.id] = { "value" => arg.values_from_properties(installed_component).first }
      end
    end
    argument_values
  end

  def import_from_library(script_files = nil, folder = nil, sub_folder = nil, project_server_id = nil)
    success = true
    error_messages = []
    @project_server = ProjectServer.find_by_id(project_server_id) if project_server_id
    integration_server_id = @project_server.present? ? @project_server.try(:id) : nil
    unless folder.nil? || script_files.nil? || script_files.empty?
      # This function is used for rearranging the imported script names with dependent on each other
      rearrange_script_files(script_files, folder, sub_folder)
      script_files.each do |script_file|
        import_attributes = nil
        render_as = nil
        maps_to = nil
        path_and_filename = File.split(script_file)
        script_type = sub_folder ? sub_folder : Script.script_class(folder)
        automation_type = folder.present? && folder == "resource_automation" ? "ResourceAutomation" : "Automation"
        logger.info('ScriptType: ' + "#{sub_folder ? sub_folder : script_type.name}") unless script_type.nil?
        resource_id = folder.present? && folder == "resource_automation" ? path_and_filename[1].split(".")[0] : nil # Used only for resource automations
        name = path_and_filename[1].split(".")[0].humanize
        if sub_folder
          path = File.join(AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH, folder, sub_folder, path_and_filename)
        else
          path = File.join(AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH, folder, path_and_filename)
        end
        if @project_server
          file_content = File.open(path).read
          content = build_integration_parameters(file_content)
        else
          content ||= File.open(path).read
        end
        if (["BMC Application Automation 8.2", "RLM Deployment Engine", "BMC Remedy 7.6.x"].include?(sub_folder) ) && (automation_type == "ResourceAutomation")
          script_helper_path = "require '#{AutomationCommon::DEFAULT_AUTOMATION_SUPPORT_PATH}/script_helper'"
          #### next line fix for DE91967 Remedy integration: Incorrect script import from library.
          eval('def import_script_parameters;nil;end;')
          import_attributes = eval("#{script_helper_path}\n#{content};import_script_parameters;") rescue nil
        end
        if import_attributes
          # {"render_as" => "Tree", "maps_to" => "Ticket"}
          import_attributes.each do |key, value|
            case key
            when "render_as"
              render_as = value
            when "maps_to"
              maps_to = value
            end
          end
        elsif folder == "resource_automation"
          render_as = "List"
          maps_to = "None"
        end
        unless script_type.nil? || content.blank?
          script_category = sub_folder ? sub_folder : script_type.name
          script = case script_category
          when 'General', 'BMC Remedy 7.6.x', 'BMC Application Automation 8.2', 'RLM Deployment Engine'
            if script_category == "BMC Application Automation 8.2" && folder == "resource_automation" && ( integration_server_id.nil? || @project_server.try(:server_type) != "BMC Application Automation")
              error_messages << ("#{path_and_filename[1]}: Integration server type of BMC Application Automation not found.")
              nil
            elsif script_category == "BMC Remedy 7.6.x" && ( integration_server_id.present? && @project_server.try(:server_type) != "Remedy via AO")
              error_messages << ("#{path_and_filename[1]}: Integration server type of Remedy via AO not found.")
              nil
            elsif script_category == "RLM Deployment Engine" && ( integration_server_id.nil? || @project_server.try(:server_type) != "RLM Deployment Engine")
              error_messages << ("#{path_and_filename[1]}: Integration server type of <u>RLM Deployment Engine</u> not found.".html_safe)
              nil
            else
              Script.create(:name => name, :description => 'Imported from library', :content => content, :integration_id => integration_server_id, :automation_category => script_category,
                            :automation_type => automation_type, :unique_identifier => resource_id, :render_as => render_as,
                            :maps_to => maps_to)
            end
          when 'BladelogicScript'
            script_type.create(:name => name, :description => 'Imported from library', :content => content, :authentication => 'default')
          when 'Hudson'
            logger.info("process hudson script")
            begin
              logger.info("process hudson script")
              if integration_server_id.nil? || @project_server.try(:server_type) != "Hudson/Jenkins"
                error_messages << ("#{path_and_filename[1]}: Integration server type of Hudson not found.")
                nil
              else
                Script.create(:name => name, :description => 'Imported from library', :content => content,
                  :integration_id => integration_server_id, :automation_category => "Hudson/Jenkins", :automation_type => automation_type,
                  :unique_identifier => resource_id, :render_as => render_as, :maps_to => maps_to )
              end
            rescue
            nil
            end
          end
        end
        success = false if (script.nil? || !script.errors.empty?)
        if !script.nil? && !script.errors.empty?
          script.errors.full_messages.each do |msg|
            error_messages << ("#{path_and_filename[1]}: " + msg)
          end
        end
        update_import_scripts_aasm_state(script)
      end
    else
      success = false
      error_messages << "Script folder can't be blank" if folder.nil?
      error_messages << "Can't Import without script" if script_files.nil? || script_files.empty?
      error_messages.join("<br>")
    end
    return success, error_messages
  end

  def update_import_scripts_aasm_state(script)
    if !script.nil? && !script.is_a?(BladelogicScript)
      script.update_attribute(:aasm_state,'released')
    end
  end

    #----------------- PRIVATE -----------------------#
  private

  def render_new
    if params.include?("stand_alone")
      render template: 'shared_scripts/new', layout: false
    else
      if request.xhr?
        if associated_model == BladelogicScript
          render template: 'shared_scripts/bladelogic/detail_new.html.erb', layout: false
        else
          render template: 'shared_scripts/detail_new', layout: false
        end
      else
        if associated_model == BladelogicScript
          render template: 'shared_scripts/bladelogic/detail_new.html.erb'
        else
          render template: 'shared_scripts/detail_new'
        end
      end
    end
  end

  def render_edit
    if request.xhr?
      if associated_model == BladelogicScript
        render template: 'shared_scripts/bladelogic/edit', layout: false
      else
        render template: 'shared_scripts/edit', layout: false
      end
    else
      if associated_model == BladelogicScript
        render template: 'shared_scripts/bladelogic/detail_edit'
      else
        render template: 'shared_scripts/detail_edit'
      end
    end
  end

  def rearrange_script_files(script_files,folder,sub_folder)
    ignore_scripts = []
    script_files.each do |script_file|
      unless ignore_scripts.include?(script_file)
        path_and_filename = File.split(script_file)
        if sub_folder
          path = File.join(AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH, folder, sub_folder, path_and_filename)
        else
          path = File.join(AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH, folder, path_and_filename)
        end
        content ||= File.open(path).read
        pa = parsed_arguments(content)
        if pa.present? && pa.is_a?(Hash)
          pa.each do |argument_name, val|
            if val.is_a?(Hash) && val.keys.include?("external_resource")
              external_resource = "./#{val['external_resource']}.rb"
              if script_files.include?(external_resource)
                if script_files.index(external_resource) > script_files.index(script_file)
                  deleted_script_name = script_files.delete(external_resource)
                  script_files.insert(script_files.index(script_file), deleted_script_name)
                end
                ignore_scripts.push(script_file)
              end
            end
          end
        end
      end
    end
  end

  def build_integration_parameters(content)
    original_data = content
    @project_server.nil? ? "\n# Integration server not found #" : @project_server.add_update_integration_values(original_data, true)
  end

  def parse_arguments(content)
    arg_string = content.match(/\s*^###\r?\n(.+?)(\r?\n)+?\s*^###\r?/m)
    result = arg_string[1] if arg_string
    result.gsub! "\t", "  " if result
    result
  end

  def parsed_arguments(content)
    parsed_args = parse_arguments(content)
    if parsed_args.present? && parsed_args.include?('#')
      parsed_args = parsed_args.gsub("#","")
    end
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

  def only_not_imported_scripts(script_files)
    script_files.sort!{ |a,b| a[1] <=> b[1] }

    script_class = case @folder
                     when 'bladelogic'
                       BladelogicScript
                     else
                       Script
                   end
    script_class = script_class
    script_files_not_imported = []
    script_files.each do |script_file|
      name = script_file[1].split(".")[0].humanize
      script_files_not_imported <<  script_file unless script_class.exists?(['name LIKE ?', "#{name}"])
    end
    script_files_not_imported
  end
end