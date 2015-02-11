################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module AutomationCommon
  require 'base64'

  DEFAULT_AUTOMATION_SUPPORT_PATH = File.join(Rails.root, "lib", "script_support")
  DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH = File.join(DEFAULT_AUTOMATION_SUPPORT_PATH, "LIBRARY")
  # automation results has been moved to comfiguration file and is loaded above automation_settings.rb
  #OUTPUT_BASE_PATH = "#{RAILS_ROOT}/public/automation_results"


  class << self
    def output_separator(phrase)
      divider = "==========================================================="
      "\n#{divider.slice(0..20)} #{phrase} #{divider.slice(0..(divider.length-phrase.length))}\n"
    end

    def platform_path(path)
      # Windows ? path.gsub("/", "\\") : path
      path
    end

    def base_url
      url = "#{GlobalSettings[:base_url]}#{ContextRoot::context_root}"
    end

    def callback_url(step, token)
      "#{base_url}/steps/#{step.id}/#{step.request_number}/callback.xml?token=#{token}" unless (token.nil? || step.nil?)
    end

    def get_output_dir(script_type, step = nil)
      sstep = ""
      if script_type == "request" && !step.nil? && !step.new_record?
        sstep = "/#{step.app_name.to_sentence.gsub(" ", "_")}/#{step.request.number.to_s}/step_#{step.id.to_s}"
        ascii_sstep = "/app_id_#{step.try(:app_id) || 'na'}/#{step.request.number.to_s}/step_#{step.id.to_s}"
      end

      outdir = platform_path("#{$OUTPUT_BASE_PATH}/#{script_type}#{sstep}").encode('UTF-8')

      # crete output dir combining ids not names to avoid non-ascii characters
      # in case any problem to create outdir
      begin
        FileUtilsUTF.mkdir_p(outdir)
      rescue
        ascii_outdir = platform_path("#{$OUTPUT_BASE_PATH}/#{script_type}#{ascii_sstep}")
        outdir       = ascii_outdir
        begin
          FileUtils.mkdir_p(ascii_outdir)
        rescue
          raise "Unable to create directory `#{outdir.inspect}`"
        end
      end

      return outdir
    end

    def get_request_dir(request)
      outdir = platform_path("#{$OUTPUT_BASE_PATH}/request/#{request.app_name.to_sentence.gsub(" ", "_")}/#{request.number.to_s}")
      FileUtilsUTF.mkdir_p(outdir)
      outdir
    end

    def append_output_file(params, phrase)
      output_file = FileInUTF.open(params["SS_output_file"], "a")
      output_file.puts phrase
      output_file.flush
      output_file.close
    end

    def get_trailer_string(params)
      case params["SS_script_target"]
        when "bladelogic"
          trailer = ""
        when "ssh", "hudson", "resource_automation", "remedy", "baa", "rlm", "script"

          trailer = "# Load the input parameters file and parse as yaml.\n"
          trailer += "script_params = load_input_params('#{params["SS_input_file"]}')\n"
          trailer += "params = script_params\n"
          trailer += "# Create a new output file and note it in the return message: sets @hand\n"
          trailer += "create_output_file(params) #sets the @hand file handle\n"

        else
          trailer = "### Trailer TBD ###"
      end
    end

    def init_run_files(params, script_content)
      # Input file
      content = clean_script_file(script_content)
      content = update_integration_values(content, params["SS_script_target"])
      content = mask_passwords(content)
      arg_file_name = params["SS_input_file"]
      ssh = (params["SS_script_target"] == "ssh")
      input_file = FileInUTF.new(arg_file_name, "w+")
      input_content = hash_to_sorted_yaml(params)
      input_file.print(input_content)
      input_file.close

      #script File
      script_file = FileInUTF.new(params["SS_script_file"], "w+")
      script_file.puts "#encoding: utf-8"
      hdr = script_header_file(params)
      script_file.print hdr

      trailer = get_trailer_string(params)
      script_file.print trailer
      script_file.print content
      script_file.print close_line(params["SS_script_target"])
      script_file.close
      File.chmod(0644, script_file.path)

      # output file
      output_file = FileInUTF.open(params["SS_output_file"], "a")
      output_file.puts(output_separator("SCRIPT TO EXECUTE"))
      output_file.puts "# Starts at Line# #{hdr.lines.count} (for debugging)"
      output_file.puts(content)
      output_file.puts(output_separator("INPUT PARAMETERS"))
      output_file.puts(input_content)
      output_file.puts "Run Executed on: #{Time.now.to_s}"
      output_file.close
    end

    def mask_passwords(content_text)
      new_text = content_text
      reg = /SS_.+assword\ =\ .+/
      items = new_text.scan(reg)
      if items.size > 0
        items.each do |it|
          parts = it.split(" = ")
          new_text.gsub!(it, "#{parts[0]} = '<private>'")
        end
      end
      new_text
    end

    def tokenize(step)
      token = "#{step.request_id.to_s}_#{step.id.to_s}_#{Time.now.to_i}"
      step.update_column(:token, token)
      token
    end

    def error_in?(results)
      if List.find_by_name("AutomationErrors").nil?
        errors = ["STDERR: ", "failed: ", "AuthenticationFailed:"]
      else
        errors = List.get_list_items("AutomationErrors")
      end
      has_error = false
      unless results.nil?
        errors.each do |er|
          lpos = results.index(er)
          has_error = true unless lpos.nil?
        end
      end
      has_error
    end

    def build_params(params, step = nil, resource_automation_script = nil)
      #params seeded in calling script
      run_time = params["SS_run_key"] ||= Time.now.to_i
      params["SS_script_support_path"] = platform_path(DEFAULT_AUTOMATION_SUPPORT_PATH)
      params["SS_base_url"] = base_url
      case params["SS_script_target"]
        when "bladelogic"
          prefix = "bl"
        when "ssh"
          prefix = "ssh"
        when "remedy"
          prefix = "remedy"
        when "resource_automation"
          prefix = "resource_automation"
        when "hudson"
          prefix = "hudson"
        when "baa"
          prefix = "baa"
        when "rlm"
          prefix = "rlm"
        when "script"
          prefix = "script"
        else
          prefix = "other"
      end
      if !step.nil? && !step.new_record?
        params["SS_output_dir"] = get_output_dir('request', step)
        step.step_script_arguments.each do |arg|
          #
          # FIXME: Rajesh Jangam
          # We are manually serializing the array using comma.
          # Ideally we should leave to YAML to serialize it into the file
          argument_value = arg.value.is_a?(Array) ? arg.value.flatten.join(",") : arg.value
          if arg.script_argument.argument_type == "in-file"
            # FIXME: Rajesh Jangam
            # We are assuming only one value over here
            # The model allows many
            puts "processing in-file"
            begin
              if arg.uploads && (arg.uploads.size > 0)
                argument_value = File.join(arg.uploads[0].attachment.root, arg.uploads[0].attachment_url)
              else
                argument_value = ""
              end
            rescue Exception => e
              puts "Error!--------------------------------"
              puts e.message
            end

          end
          unless arg.script_argument.class.to_s == "BladelogicScriptArgument"
            if argument_value.present?
              if arg.script_argument.argument_type == "in-datetime"
                argument_value = Time.parse(argument_value).to_datetime
              elsif arg.script_argument.argument_type == "in-date"
                argument_value = argument_value.to_date
              end
            end
          end
          params[arg.argument] = arg.script_argument.is_private ? private_flag(argument_value) : argument_value
        end
        if prefix == "bl"
          if step.script.authentication == 'step' && step.owner.bladelogic_user
            #  ---- NOTE: Now we need a profile, not username #
            params["SS_auth_type"] = 'step'
            params["bladelogic_profile"] = step.owner.bladelogic_user.username
            params["bladelogic_role"] = step.bladelogic_role
          end
        end
        params["SS_token"] = tokenize(step)
        params["SS_process_pid"] = -1
        params["SS_callback_url"] = callback_url(step, params["SS_token"])
        params.merge!(step.create_package_instance_for_step_run)
        params.merge!(step.headers_for_step(params))

        headers_for_request = step.request.headers_for_request
        headers_for_request.delete("request_notes")
        params.merge!(headers_for_request)

        params["SS_api_token"] = private_flag(User.find(params["step_user_id"].to_i).api_key)
      else
        # Arguments set in calling script
        params["SS_output_dir"] = get_output_dir(params["SS_script_type"])
        if step
          begin
            params.merge!(step.create_package_instance_for_step_run)
            params.merge!(step.headers_for_step(params))
          rescue Exception => e
            puts "++++++++++++++++++Exception: #{e.message} +++++++++++++++++++++++"
          end
        end
      end

      unless step.nil?
        app_comp = step.installed_component.try(:application_component)
        if app_comp
          mappings = app_comp.application_component_mappings || []
          mappings.each do |mapping|
            params["SS_component_mapping_#{mapping.project_server_id}"] = mapping.data
          end
        end
      end

      project_server = nil
      if resource_automation_script.blank?
        project_server = step.try(:script).try(:project_server)
      else
        project_server = resource_automation_script.try(:project_server)
      end

      if project_server
        params["SS_project_server"] = project_server.name
        params["SS_project_server_id"] = project_server.id
      end

      script_id = resource_automation_script.nil? ? "" : "#{resource_automation_script.try(:id)}_"
      params["SS_output_file"] = platform_path("#{params["SS_output_dir"]}/output_#{script_id}#{run_time}.txt")
      params["SS_input_file"] = platform_path("#{params["SS_output_dir"]}/#{prefix}input_#{script_id}#{run_time}.txt")
      params["SS_script_file"] = platform_path("#{params["SS_output_dir"]}/script_#{prefix}_#{script_id}#{run_time}.txt")
      params["SS_automation_results_dir"] = platform_path($OUTPUT_BASE_PATH)
      return params
    end

    def build_server_params(step_or_id)
      ret = {}
      comp = nil
      unless step_or_id.nil?
        if step_or_id.class == Step  #Running from step
          comp = step_or_id.installed_component unless (step_or_id.server_ids.nil? || step_or_id.server_ids.empty?)
          comp = step_or_id.installed_component unless (step_or_id.server_aspect_ids.nil? || step_or_id.server_aspect_ids.empty?)
        else #step_or_id.class == Fixnum  # Running from test
          comp = InstalledComponent.find_by_id(step_or_id) unless (step_or_id.nil? || step_or_id.try(:to_i) < 1)
          test = true
        end
        unless comp.nil?
          comp.server_associations.each_with_index do |serv, idx|
            if step_or_id.class != Step || step_or_id.server_ids.include?(serv.id) || step_or_id.server_aspect_ids.include?(serv.id)
              skey = (idx+1) * 1000
              if serv.is_a?(Server)
                ret["server#{skey.to_s}_name"] = serv.name
                ret["server#{(skey += 1).to_s}_dns"] = serv.dns
                ret["server#{(skey += 1).to_s}_ip_address"] = serv.ip_address
                ret["server#{(skey += 1).to_s}_os_platform"] = serv.os_platform
              else
                ret["server#{skey.to_s}_name"] = "#{serv.server.name}:#{serv.name}"
              end
              serv.properties.active.each_with_index do |prop, num|
                tmp = prop.literal_value_for(serv)
                tmp = private_flag(tmp) if prop.is_private
                ret["server#{(num + skey + 1).to_s}_#{prop.name}"] = tmp
              end
            end
          end
        end
      end
      ret
    end

    def test_script_values(form_params)
      params = {}
      app = app_from_id(form_params["app_id"])
      if app
        params["SS_application"] = app.name
      end
      params["SS_environment"] = environment_name_from_id(form_params["app_env_id"])
      type_of_object = form_params["step_related_object_type"]
      params["step_object_type"] = type_of_object
      if type_of_object == "Component"
        params["SS_component"] = component_name_from_id(form_params["installed_component_id"])
        params.merge!(AutomationCommon.test_property_values_component(form_params["installed_component_id"]))
      else
        params.merge!(AutomationCommon.test_script_values_package(form_params, app))
      end
      params
    end

    def test_script_values_package(form_params, app)
      params = {}
      package_id_s = form_params["package_id"]
      if package_id_s and app
        package_id = package_id_s.to_i
        package = Package.find(package_id)
        params["step_package_id"] = package_id
        params["step_package_name"] = package.name
        params.merge!(AutomationCommon.test_script_values_package_instance(form_params, app, package))
      end
      params
    end

    def test_script_values_package_instance(form_params, app, package)
      params = {}
      app_package = app.app_package_for_package_id(package.id)
      instance_type = form_params["package_instance_id"]
      if instance_type.blank?
        params.merge!(AutomationCommon.test_property_values_app_package(app_package))
        params.merge!(AutomationCommon.test_values_references(package.references))
      else
        instance = PackageInstance.find(instance_type.to_i)
        params["step_package_instance_id"] = instance.id
        params["step_package_instance_name"] = instance.name
        params.merge!(AutomationCommon.test_property_values_instance(instance))
        params.merge!(AutomationCommon.test_property_values_instance(instance, "step_instance_property_"))
        params.merge!(AutomationCommon.test_values_references(instance.instance_references))
      end
      params
    end

    def app_from_id(curid)
      (curid.nil? || curid == '') ? nil : App.find_by_id(curid)
    end

    def environment_name_from_id(curid)
      curid.nil? ? "" : ApplicationEnvironment.find_by_id(curid).environment.name
    end

    def component_name_from_id(curid)
      curid.nil? ? "" : InstalledComponent.find_by_id(curid).component.name
    end

    def test_values_references( references )
      res = {}
      unless references.nil?
        res["step_ref_ids"] = references.map { | r| r.id }.join ","
        res["step_ref_names"] =  references.map { |r| r.name }.join ","
        references.each do | reference |
          res["step_ref_#{reference.name}_uri"] =  reference.uri
          res["step_ref_#{reference.name}_server"] =  reference.server.name
          res["step_ref_#{reference.name}_method"] = reference.resource_method
          reference.property_values.each do | property_value |
            res["step_ref_#{reference.name}_property_#{property_value.name}"] =  property_value.value
          end
        end
      end
      res
    end

    def test_property_values_instance(instance, prefix = "")
      res = {}
      unless instance.nil?
        instance.current_property_values.each do |prop|
          res[prefix + prop.name] = prop.value
          res[prefix + prop.name] = private_flag(prop.value) if prop.property.is_private
        end
      end
      res
    end

    def test_property_values_app_package(app_package)
      res = {}
      unless app_package.nil?
        app_package.current_property_values.each do |prop|
          res[prop.name] = prop.value
          res[prop.name] = private_flag(prop.value) if prop.property.is_private
        end
      end
      res
    end

    def test_property_values_component(component_id)
      res = {}
      unless component_id.nil?
        cur_component = InstalledComponent.find(component_id.to_i)
        cur_component.current_property_values.each do |prop|
          res[prop.name] = prop.value
          res[prop.name] = private_flag(prop.value) if prop.property.is_private
        end
        res["SS_component_version"] = cur_component.version
        res["SS_component_template_0"] = cur_component.application_component.component_templates.first.name unless cur_component.application_component.component_templates.empty?
      end
      res
    end


    def bladelogic_header_file(params)
      header = File.open(platform_path("#{DEFAULT_AUTOMATION_SUPPORT_PATH}/bladelogic_script_header.py")).read
      if !GlobalSettings.bladelogic_ready?
        raise "BladeLogic is not configured. Please configure it via Environment->Automation->BMC BladeLogic->Show BladeLogic Authentication"
      end
      if params["SS_auth_type"].nil? || params["SS_auth_type"] == "default"
        header.gsub!("$$BLADELOGIC_PROFILE",  GlobalSettings[:bladelogic_profile])
        header.gsub!("$$BLADELOGIC_ROLENAME", GlobalSettings[:bladelogic_rolename])
      else
        header.gsub!("$$BLADELOGIC_PROFILE",  params["bladelogic_profile"])
        header.gsub!("$$BLADELOGIC_ROLENAME", params["bladelogic_role"])
      end
      header.gsub!("$$BLADELOGIC_INPUTFILE", params["SS_input_file"])
      header.gsub!("$$BLADELOGIC_USERNAME", GlobalSettings[:bladelogic_username])
      header.gsub!("$$BLADELOGIC_PASSWORD", GlobalSettings[:bladelogic_password])
      header.gsub!("$$APPPATH", DEFAULT_AUTOMATION_SUPPORT_PATH)
    end


    def script_header_file(params)
      case params["SS_script_target"]
        when "bladelogic"
          header = bladelogic_header_file(params)
        when "ssh"
          header = ssh_script_header(params)
        when "resource_automation", "remedy", "baa", "rlm", "script"
          header = resource_automation_script_header(params)
        when "hudson"
          header = hudson_script_header(params)
        else
          header = "other"
      end
    end

    def ssh_script_header(params = {})
      File.open(platform_path("#{DEFAULT_AUTOMATION_SUPPORT_PATH}/ssh_script_header.rb")).read
    end

    def hudson_script_header(params = {})
      header = File.open(platform_path("#{DEFAULT_AUTOMATION_SUPPORT_PATH}/hudson_script_header.rb")).read
      header += File.open(platform_path("#{DEFAULT_AUTOMATION_SUPPORT_PATH}/ssh_script_header.rb")).read
    end

    def resource_automation_script_header(params = {})
      hudson_script_header(params)
    end

    def private_flag(val)
      (val.nil? || val == "") ? "" : PRIVATE_PREFIX + val
    end

    def redact(val_or_path)
      if val_or_path[0,8] == RAILS_ROOT[0,8]  # An input file path
        conts = File.open(val_or_path).read
      else
        conts = val_or_path
      end
      #conts.gsub(/#{PRIVATE_PREFIX}.*$/, "XXXXXXXXXXXXX")
      val_or_path
    end

    def clean_script_file(content)
      lines_to_clean = [
          'params = load_input_params(ENV["_SS_INPUTFILE"])',
          "\n@hand.close\n",
          'create_output_file(params)',
          'params = load_input_params(os.environ["_SS_INPUTFILE"])',
          'FHandle = open(params["SS_output_file"], "a")',
          'FHandle = open(params["output_file"], "a")',
          "\nFHandle.close()\n",
          'bl_profile_name = os.environ["_SS_PROFILE"]',
          'bl_role_name	= os.environ["_SS_ROLENAME"]',
          "\nsys.exit(0)\n"]
      lines_to_clean.each do |phrase|
        if content.include?(phrase)
          content.gsub!(phrase,"")
        end
      end
      content
    end

    def close_line(stype)
      case stype
        when "bladelogic"
          res = <<-END
FHandle.close()
sys.exit(0)
          END
        when "ssh", "hudson"
          res = <<-END
#Close the file handle
@hand.close
          END
        else
          res = ""
      end
      res
    end

    def update_integration_values(content, script_type)
      #=== Hudson Integration Server: SS Hudson ===#
      #[integration_id=2]
      #SS_hudson_dns = "http://ec2-50-16-13-51.compute-1.amazonaws.com:8083"
      #SS_hudson_username = "streamstep"
      #SS_hudson_password = "-private-"
      #=== End ===#
      id_reg = /\[integration_id=.+\]/
      reg = /\#\=\=\=.+\=\=\= End \=\=\=\#/m
      has_id = content.scan(id_reg)
      unless has_id.empty?
        int_id = has_id[0].split("=")[1].gsub("]","").to_i
        integration = ProjectServer.find(int_id)
        unless integration.nil?
          new_header = integration.build_integration_script_header(false)
          content = content.gsub(reg, new_header)
        end
      end
      content
    end

    def decrypt(val)
      enc = Base64::decode64(val.gsub(PRIVATE_PREFIX,"")).reverse
      enc = Base64::decode64(enc).gsub(PRIVATE_PREFIX,"")
    end

    def encrypt(val)
      enc = Base64::encode64(val).reverse
      enc = PRIVATE_PREFIX + Base64::encode64(enc).gsub("\n","")
    end

    def encrypt_values(hsh_params)
      len = PRIVATE_PREFIX.length
      hsh_params.each do |item, value|
        if value.class == String
          hsh_params[item] = encrypt(value.gsub(PRIVATE_PREFIX, "")) unless value.index(PRIVATE_PREFIX).nil?
        end
      end
      return hsh_params
    end

    def hash_to_sorted_yaml(hsh)
      # fix for DE80292
      # use simple ruby-style parsing to avoid unicode chars problems in `to_yaml`
      # r = Hash[hsh.sort].to_yaml
      yaml_like = ""
      hsh.sort.each{ |p| yaml_like += (p[0] + ": '" + p[1].to_s.gsub("'", "''") + "'\n") }

      return yaml_like
    end

    def hash_string(hsh)
      res = "{"
      hsh.each{ |p, v| res += "'#{p}'=>'#{v}',"}
      res.chomp(",") + "}"
    end
  end


end
