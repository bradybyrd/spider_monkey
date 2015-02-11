###
# Package:
#   name: RLM Package
#   position: A1:B1
#   type: in-external-single-select
#   external_resource: rlm_packages
#   required: yes
# Instance:
#   name: Enter Package instance name
#   type: in-text
#   position: E1:F1
#   required: yes
# Route:
#   name: Route
#   type: in-external-single-select
#   external_resource: rlm_routes
#   position: A3:B3
#   required: yes
# Environment:
#   name: Environment
#   type: in-external-single-select
#   external_resource: rlm_route_environments
#   position: E3:F3
#   required: yes
# Channels:
#   name: Environment channels
#   type: in-external-single-select
#   external_resource: rlm_environment_channels
#   position: A4:F4
#   required: no
# Log Format:
#   name: Log Format
#   type: in-list-single
#   list_pairs: 0,Old Format|1,New Format
#   position: A5:B5
#   required: yes
# Set Properties:
#   name: Set Properties
#   type: in-external-single-select
#   external_resource: rlm_package_properties
#   position: A6:F6
#   required: no
# Deployment Log File:
#   name: Deployment Log HTML
#   type: out-file
#   position: A1:F1
# Deployment Log URL:
#   name: Deployment Log HTML
#   type: out-url
#   position: A2:F2
###
begin

  require 'lib/script_support/rlm_utilities'
  require 'yaml'
  require 'uri'
  require 'active_support/all'

  params["direct_execute"] = true

  RLM_USERNAME = SS_integration_username
  RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
  RLM_BASE_URL = SS_integration_dns
  RESULT_DIR = params['SS_automation_results_dir']
  LOG_FORMAT = params['Log Format']

  def attach_logs(object_id, command, results_command)
    begin
      logs = RlmUtilities.get_logs(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, object_id, command, LOG_FORMAT)
    rescue Exception => e
      warning_message = "\nWARNING - Something went wrong during parsing #{command}"
      write_to warning_message
      logs = warning_message + " \n\nException \nMessage: - #{e.message}\nBacktrace: #{e.backtrace.inspect}"
    end
    if logs
      log_file_path = RlmUtilities.write_logs_to_file(object_id, RESULT_DIR, logs)
      pack_response results_command, log_file_path
    end
  end

  #######################Get package Id and package name
  package_id = params['Package'].split('*')[0]
  array_split = params['Package'].split('*')
  array_split.delete_at(0)
  package_name = array_split.join('*')

  #####################Set Q prop values from BRPM####################################################
  begin
    params.each_pair do |k,v|
      prop_name = k.gsub('DE_', '')
      if (k =~ /^#{'DE_'}/) && !v.blank? && params['Set Properties'].present? && params['Set Properties'].split(',').include?(prop_name)
        write_to("Setting value for property: #{prop_name}")
        encrypt = params["#{k}_encrypt"]
        RlmUtilities.rlm_set_q_property_value(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, "#{package_name}:#{params['Instance']}", 'instance property add', prop_name, v, encrypt)
      end
    end
  rescue Exception => e1
    write_to("Could not set property values: #{e1.message}")
    raise 'Error while setting property values.'
  end

  ################Code to check if environment is changed through choose template or in the new Request template ##########
  if params['Environment'].include?('inherited')
    rlm_environments = RlmUtilities.get_route_environments( RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, params['Route'], params['SS_environment'])
    if rlm_environments.present? && rlm_environments.first.keys.include?("#{params['SS_environment']}(inherited from request)")
      new_env_id = rlm_environments.first["#{params['SS_environment']}(inherited from request)"].split('-')[0] rescue nil
    end
  end
  new_env_id ||= params['Environment'].split('-')[0]


  ########################Instance Deployment stage begins###############################
  deployment_instance_id = RlmUtilities.deploy_package_instance(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, "#{package_name}:#{params['Instance']}", params['Route'], new_env_id, params['Channels'])
  if deployment_instance_id.nil?
    write_to('Operation failed: Cannot deploy instance.')
    raise 'Error while deploying the package instance.'
  else
    write_to('package instance deployment is now started.')
  end

  ########################Check the status of deployment###############################
  delay = 5 # This delay is required as after creating the instance, status may not immediately go to constructing
  begin
    sleep(delay)
    deploy_status = RlmUtilities.get_deploy_status(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, deployment_instance_id)
    delay = 10
  end while (deploy_status != 'pass' && deploy_status != 'fail' && deploy_status != 'cancelled')

  pack_response 'Deployment Log URL', "#{RLM_BASE_URL}/index.php/delivery/wiz_action_results/view/#{deployment_instance_id}"
  attach_logs(deployment_instance_id, 'process deployment log', 'Deployment Log File')

  if deploy_status == 'fail' ||  deploy_status == 'cancelled' || deploy_status != 'pass'
    write_to 'Operation failed: There were some problem while deploying the package instance.'
    exit(1)
  else
    write_to('package instance deployed successfully.')
  end

rescue Exception => e
  write_to("Operation failed: #{e.message}, Backtrace:\n#{e.backtrace.inspect}")
end
