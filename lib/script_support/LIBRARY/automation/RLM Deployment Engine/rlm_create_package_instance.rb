###
# Package:
#   name: RLM Package
#   position: A1:B1
#   type: in-external-single-select
#   external_resource: rlm_packages
#   required: yes
# Instance Name:
#   name: Instance Name
#   position: E1:F1
#   type: in-text
#   required: no
# Locked:
#   name: Lock instances to prevent changes
#   type: in-list-single
#   list_pairs: 0,No|1,Yes|
#   position: A3:B3
#   required: yes
# Contents:
#   name: Package references
#   type: in-external-single-select
#   external_resource: rlm_package_content_references
#   position: A5:F5
#   required: yes
# Log Format:
#   name: Log Format
#   type: in-list-single
#   list_pairs: 0,Old Format|1,New Format
#   position: A6:B6
#   required: yes
# Set Properties:
#   name: Set Properties
#   type: in-external-single-select
#   external_resource: rlm_package_properties
#   position: A7:F7
#   required: no
# Package Instance:
#   name: Package instance name
#   type: out-text
#   position: A1:F1
# Package Instance Log:
#   name: Package instance Logs
#   type: out-file
#   position: A2:F2
# Package Instances:
#   name: Package instances
#   type: out-url
#   position: A3:F3
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
        RlmUtilities.rlm_set_q_property_value(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, package_id, 'package property add', prop_name, v, encrypt)
      end
    end
  rescue Exception => e1
    write_to("Could not set property values: #{e1.message}")
    raise 'Error while setting property values.'
  end

  ########################Create package instance#################################################
  package_instance_response = RlmUtilities.create_package_instance(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, package_id, params['Locked'], params['Instance Name'])
  package_instance_id = package_instance_response[0]['id'] rescue nil
  if package_instance_id.nil?
    write_to('Operation failed: package instance creation failed.')
    raise 'Error while creating the package instance.'
  else
    pack_response 'Package Instance', "#{package_instance_response[0]['value'].split(' ')[5]}:#{package_instance_response[0]['value'].split(' ')[2]}" rescue nil
    write_to('package instance created successfully...')
  end

  ########################Check the status of package instance created###############################
  delay = 5 # This delay is required as after creating the instance, status may not immediately go to constructing
  begin
    sleep(delay)
    package_instance_status = RlmUtilities.get_package_instance_status(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, package_instance_id)
    delay = 10
  end while (package_instance_status != 'Ready' && package_instance_status != 'Error')

  pack_response 'Package Instances', "#{RLM_BASE_URL}/index.php/delivery/wiz_app_actions/instances/#{package_id}/Asset"
  attach_logs(package_instance_id, 'instance log', 'Package Instance Log')

  if package_instance_status == 'Error' || package_instance_status != 'Ready'
    write_to 'Operation failed: There were some problem while creating the package instance.'
    exit(1)
  else
    write_to('package instance is now in Ready state.')
  end

rescue Exception => e
  write_to("Operation failed: #{e.message}, Backtrace:\n#{e.backtrace.inspect}")
end