require 'json'
require 'rest-client'
require 'uri'
require 'savon'
require 'base64'

module BaaUtilities
  Savon.configure do |config|
    config._logger.filter << :password
  end

  # Next line is fix for defect DE90050: Automation steps given out of memory
  # nokogiri parser use less memory than REXML (default parser)
  Nori.parser = :nokogiri

  class << self

    # change to true for use with BSA 8.5 SP1 Patch 2 (or Patch 3)
    # also provide correct path to certificate at CERTIFICATE_PATH
    SECURITY_MODE = false

    CERTIFICATE_PATH = '/opt/bmc/RLM/cert/blappserver.pem'
    CIPHERS = 'kEDH+AESGCM'

    def rest_version
      '8.2'
    end

    def get_type_url(execute_against)
      case execute_against
      when 'servers'
        return '/type/PropertySetClasses/SystemObject/Server'
      when 'components'
        return '/type/PropertySetClasses/SystemObject/Component'
      when 'staticServerGroups', 'staticComponentGroups'
        return '/type/PropertySetClasses/SystemObject/Static Group'
      when 'smartServerGroups', 'smartComponentGroups'
        return '/type/PropertySetClasses/SystemObject/Smart Group'
      end
    end

    def get_execute_against_operation(execute_against)
      case execute_against
      when 'servers'
        return 'executeAgainstServers'
      when 'components'
        return 'executeAgainstComponents'
      when 'staticServerGroups'
        return 'executeAgainstStaticServerGroups'
      when 'staticComponentGroups'
        return 'executeAgainstStaticComponentGroups'
      when 'smartServerGroups'
        return 'executeAgainstSmartServerGroups'
      when 'smartComponentGroups'
        return 'executeAgainstSmartComponentGroups'
      end
    end

    def execute_job_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, operation, arguments_hash)
      action_sub_url = "#{job_url}/Operations/#{operation}"
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url)

      response = build_rest_resource(url).post(arguments_hash.to_json, content_type: :json, accept: :json)
      response = parse_rest_response(response, 'posting', url)

      if response && response['OperationResultResponse'] &&
        response['OperationResultResponse']['OperationResult'] &&response['OperationResultResponse']['OperationResult']['value']

        query_url = response['OperationResultResponse']['OperationResult']['value']

        return execute_sub_query(baa_base_url, baa_username, baa_password, baa_role, query_url)
      end
      nil
    end

    def execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, execute_against)
      uris = []
      targets.each do |t|
        uris << t
      end

      sub_h = { 'name' => execute_against,
                'type' => get_type_url(execute_against),
                'uris' => uris }

      h = { 'OperationArguments' => [sub_h] }

      operation = get_execute_against_operation(execute_against)
      execute_job_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, operation, h)
    end

    def execute_job_against_servers(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'servers')
    end

    def execute_job_against_static_server_groups(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'staticServerGroups')
    end

    def execute_job_against_smart_server_groups(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'smartServerGroups')
    end

    def execute_job_against_components(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'components')
    end

    def execute_job_against_static_component_groups(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'staticComponentGroups')
    end

    def execute_job_against_smart_component_groups(baa_base_url, baa_username, baa_password, baa_role, job_url, targets)
      execute_job_against_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, targets, 'smartComponentGroups')
    end

    def execute_job(baa_base_url, baa_username, baa_password, baa_role, job_url)
      execute_job_internal(baa_base_url, baa_username, baa_password, baa_role, job_url, 'execute', {})
    end

    def get_id_from_db_key(db_key)
      last_component = db_key.split(':').last
      last_component ? last_component.split('-')[0].to_i : nil
    end

    def get_job_run_db_key(baa_base_url, baa_username, baa_password, baa_role, job_run_url)
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, job_run_url)
      response = get_rest_response(url)

      if response['PropertySetInstanceResponse'] && response['PropertySetInstanceResponse']['PropertySetInstance']
        response['PropertySetInstanceResponse']['PropertySetInstance']['dbKey']
      else
        nil
      end
    end

    def get_job_run_id(baa_base_url, baa_username, baa_password, baa_role, job_run_url)
      db_key = get_job_run_db_key(baa_base_url, baa_username, baa_password, baa_role, job_run_url)

      db_key.nil? ? nil : get_id_from_db_key(db_key)
    end

    def get_object_property_value(baa_base_url, baa_username, baa_password, baa_role, object_url, property, bquery = '')
      action_sub_url = "#{object_url}/PropertyValues/#{property}/"
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url, bquery)
      response = get_rest_response(url)

      if response['PropertyValueChildrenResponse'] && response['PropertyValueChildrenResponse']['PropertyValueChildren'] &&
        response['PropertyValueChildrenResponse']['PropertyValueChildren']['PropertyValueElements']
        response['PropertyValueChildrenResponse']['PropertyValueChildren']['PropertyValueElements']['Elements']
      else
        nil
      end
    end

    def get_job_result_url(baa_base_url, baa_username, baa_password, baa_role, job_run_url)
      elements = get_object_property_value(baa_base_url, baa_username, baa_password, baa_role, job_run_url, 'JOB_RESULTS*')
      element = elements[0] if elements
      results_psi = element['PropertySetInstance'] if element
      return results_psi['uri'] if results_psi
      nil
    end

    def get_per_target_results_internal(baa_base_url, baa_username, baa_password, baa_role, job_result_url, property, clazz)
      bquery = "&bquery=select name, had_errors, had_warnings, requires_reboot, exit_code*, requires_reboot from \"SystemObject/#{clazz}\""

      h = {}
      elements = get_object_property_value(baa_base_url, baa_username, baa_password, baa_role, job_result_url, property, bquery)
      if elements
        elements.each do |jrd|
          if jrd['PropertySetInstance']
            target = jrd['PropertySetInstance']['name']
            properties = {}
            if jrd['PropertySetInstance']['PropertyValues']
              values = jrd['PropertySetInstance']['PropertyValues']['Elements']
              if values
                values.each do |val|
                  properties[val['name']] = val['value']
                end
              end
            end
            h[target] = properties
          end
        end
      end
      h
    end

    def get_per_target_server_results(baa_base_url, baa_username, baa_password, baa_role, job_result_url)
      get_per_target_results_internal(baa_base_url, baa_username, baa_password, baa_role, job_result_url, 'JOB_RESULT_DEVICES*', 'Job Result Device')
    end

    def get_per_target_component_results(baa_base_url, baa_username, baa_password, baa_role, job_result_url)
      get_per_target_results_internal(baa_base_url, baa_username, baa_password, baa_role, job_result_url, 'JOB_RESULT_COMPONENTS*', 'Job Result Component')
    end

    def get_per_target_results(baa_base_url, baa_username, baa_password, baa_role, job_result_url)
      h = {}
      h['Server'] = get_per_target_server_results(baa_base_url, baa_username, baa_password, baa_role, job_result_url)
      h['Component'] = get_per_target_component_results(baa_base_url, baa_username, baa_password, baa_role, job_result_url)
      h
    end

    ###################################################################################
    #
    # Gets a list of components for specified component template
    #
    ###################################################################################
    def get_components_for_component_template(baa_base_url, baa_username, baa_password, baa_role, component_template_id)
      component_template_url = "/id/#{get_model_type_to_psc_name('TEMPLATE')}/#{component_template_id}"
      get_object_property_value(baa_base_url, baa_username, baa_password, baa_role, component_template_url, 'COMPONENTS*').collect {|item| item['PropertySetInstance']}
    end

    def get_model_type_to_psc_name(model_type)
      case model_type
      when 'JOB_GROUP'
        return 'SystemObject/Static Group/Job Group'
      when 'DEPOT_GROUP'
        return 'SystemObject/Static Group/Abstract Depot Group/Depot Group'
      when 'STATIC_SERVER_GROUP'
        return 'SystemObject/Static Group/Static Server Group'
      when 'STATIC_COMPONENT_GROUP'
        return 'SystemObject/Static Group/Static Component Group'
      when 'TEMPLATE_GROUP'
        return 'SystemObject/Static Group/Template Group'
      when 'SMART_JOB_GROUP', 'SMART_SERVER_GROUP', 'SMART_DEVICE_GROUP', 'SMART_COMPONENT_GROUP', 'SMART_DEPOT_GROUP', 'SMART_TEMPLATE_GROUP'
        return 'SystemObject/Smart Group'
      when 'SERVER'
        return 'SystemObject/Server'
      when 'COMPONENT'
        return 'SystemObject/Component'
      when 'BLPACKAGE'
        return 'SystemObject/Depot Object/BLPackage'
      when 'AIX_PATCH_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/AIX Patch'
      when 'AIX_PACKAGE_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/AIX Package'
      when 'HP_PRODUCT_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/HP-UX Product'
      when 'HP_BUNDLE_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/HP-UX Bundle'
      when 'HP_PATCH_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/HP-UX Patch'
      when 'RPM_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/RPM'
      when 'SOLARIS_PATCH_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Solaris Patch'
      when 'SOLARIS_PACKAGE_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Solaris Package'
      when 'HOTFIX_WINDOWS_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Win Depot Software/Hotfix'
      when 'SERVICEPACK_WINDOWS_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Win Depot Software/OS Service Pack'
      when 'MSI_WINDOWS_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Win Depot Software/MSI Package'
      when 'INSTALLSHIELD_WINDOWS_INSTALLABLE'
        return 'SystemObject/Depot Object/Software/Win Depot Software/InstallShield Package'
      when 'FILE_DEPLOY_JOB'
        return 'SystemObject/Job/File Deploy Job'
      when 'DEPLOY_JOB'
        return 'SystemObject/Job/Deploy Job'
      when 'NSH_SCRIPT_JOB'
        return 'SystemObject/Job/NSH Script Job'
      when 'SNAPSHOT_JOB'
        return 'SystemObject/Job/Snapshot Job'
      when 'COMPLIANCE_JOB'
        return 'SystemObject/Job/Compliance Job'
      when 'AUDIT_JOB'
        return 'SystemObject/Job/Audit Job'
      when 'TEMPLATE'
        return 'SystemObject/Component Template'
      end
    end

    def get_model_type_to_model_type_id(model_type)
      case model_type
      when 'JOB_GROUP'
        return 5005
      when 'SMART_JOB_GROUP'
        return 5006
      when 'STATIC_SERVER_GROUP'
        return 5003
      when 'SMART_SERVER_GROUP'
        return 5007
      when 'DEPOT_GROUP'
        return 5001
      when 'SMART_DEPOT_GROUP'
        return 5012
      when 'TEMPLATE_GROUP'
        return 5008
      when 'SMART_TEMPLATE_GROUP'
        return 5016
      when 'STATIC_COMPONENT_GROUP'
        return 5014
      when 'SMART_COMPONENT_GROUP'
        return 5015
      end
    end

    def is_a_group(model_type)
      groups = %w(JOB_GROUP DEPOT_GROUP STATIC_COMPONENT_GROUP STATIC_SERVER_GROUP TEMPLATE_GROUP DEVICE_GROUP
          SMART_SERVER_GROUP SMART_DEVICE_GROUP SMART_JOB_GROUP SMART_COMPONENT_GROUP SMART_DEPOT_GROUP)
      groups.include? model_type
    end

    def get_child_objects_from_parent_group(baa_base_url, baa_username, baa_password, baa_role, parent_object_type, parent_id, child_object_type)
      action_sub_url = "/id/#{get_model_type_to_psc_name(parent_object_type)}/#{parent_id}/"
      bquery = "&bquery=select name from \"#{get_model_type_to_psc_name(child_object_type)}\""
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url, bquery)
      response = get_rest_response(url)

      if is_a_group(child_object_type)
        objects = response['GroupChildrenResponse']['GroupChildren']['Groups']
      else
        objects = response['GroupChildrenResponse']['GroupChildren']['PropertySetInstances']
      end
      return objects['Elements'] if objects
      nil
    end

    def get_root_group_name(object_type)
      case object_type
      when 'JOB_GROUP'
        return 'Jobs'
      when 'DEPOT_GROUP'
        return 'Depot'
      when 'STATIC_SERVER_GROUP'
        return 'Servers'
      when 'STATIC_COMPONENT_GROUP'
        return 'Components'
      when 'TEMPLATE_GROUP'
        return 'Component Templates'
      end
    end

    def get_root_group(baa_base_url, baa_username, baa_password, baa_role, object_type)
      action_sub_url = "/group/#{get_root_group_name(object_type)}"
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url)

      response = get_rest_response(url)

      response['GroupResponse']['Group'] rescue nil
    end

    def find_job_from_job_folder(baa_base_url, baa_username, baa_password, baa_role, job_name, job_model_type, job_group_rest_id)
      action_sub_url = "/id/#{get_model_type_to_psc_name(job_model_type)}/#{job_group_rest_id}/"
      bquery = "&bquery=select name from \"SystemObject/Job\" "
      bquery += " where name = \"#{job_name}\""
      url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url, bquery)

      response = get_rest_response(url)

      unless response['GroupChildrenResponse']['GroupChildren'].has_key? 'PropertySetInstances'
        raise "Could not find job #{job_name} inside selected job folder."
      end

      # return job_obj
      response['GroupChildrenResponse']['GroupChildren']['PropertySetInstances']['Elements'][0] rescue nil
    end

    ########################################################################################
    #                                   SOAP SERVICES                                      #
    ########################################################################################

    def baa_soap_login(baa_base_url, baa_username, baa_password, cache_cred = true)
      client = get_soap_client(baa_base_url, 'LoginService')

      response = client.request(:login_using_user_credential) do |soap|
        soap.endpoint = "#{baa_base_url}/services/LoginService"
        soap.body = {userName: baa_username, password: baa_password, authenticationType: 'SRP'}
      end

      session_id = response.body[:login_using_user_credential_response][:return_session_id]
      store_cred(session_id, baa_username, baa_password) if cache_cred
      session_id
    end

    def baa_soap_assume_role(baa_base_url, baa_role, session_id)
      client = get_soap_client(baa_base_url, 'AssumeRoleService', 300)

      response = client.request(:assume_role) do |soap|
        soap.endpoint = "#{baa_base_url}/services/AssumeRoleService"
        soap.header = {'ins0:sessionId' => get_real_session_id(session_id)}
        soap.body = {roleName: baa_role}
      end
      store_role(session_id, baa_role)
      response
    end

    def baa_soap_validate_cli_result(result)
      if result && (result.is_a? Hash)
        return result if result[:success] != false
        raise "Command execution failed: #{result[:error]}, #{result[:comments]}"
      else
        raise "Command execution did not return a valid response: #{result.inspect}"
      end
    end

    def baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id, namespace, command, args, payload)
      client = get_soap_client(baa_base_url, 'CLITunnelService', 300)

      execute_with_session_expiration_check(baa_base_url, session_id) do
        response = client.request(:execute_command_using_attachments) do |soap|
          soap.endpoint = "#{baa_base_url}/services/CLITunnelService"
          soap.header = {'ins1:sessionId' => get_real_session_id(session_id)}

          body_details = {nameSpace: namespace, commandName: command, commandArguments: args}
          body_details.merge!({payload: payload}) if payload

          soap.body = body_details
        end

        result = response.body[:execute_command_using_attachments_response][:return]
        baa_soap_validate_cli_result(result)
      end
    end

    def baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, namespace, command, args)
      client = get_soap_client(baa_base_url, 'CLITunnelService', 300)

      execute_with_session_expiration_check(baa_base_url, session_id) do
        response = client.request(:execute_command_by_param_list) do |soap|
          soap.endpoint = "#{baa_base_url}/services/CLITunnelService"
          soap.header = {'ins1:sessionId' => get_real_session_id(session_id)}
          soap.body = {nameSpace: namespace, commandName: command, commandArguments: args}
        end

        result = response.body[:execute_command_by_param_list_response][:return]
        baa_soap_validate_cli_result(result)
      end
    end

    def baa_soap_create_blpackage_deploy_job(baa_base_url, session_id, job_folder_id, job_name, package_db_key, targets)
      if targets.nil? || targets.empty?
        raise 'At least one target needs to be specified while creating a blpackage deploy job'
      end

      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', 'createDeployJob',
                  [
                    job_name,                       #deployJobName
                    job_folder_id,                  #groupId
                    package_db_key,                 #packageKey
                    1,                              #deployType (0 = BASIC, 1 = ADVANCED)
                    targets.first,                  #serverName
                    true,                           #isSimulateEnabled
                    true,                           #isCommitEnabled
                    false,                          #isStagedIndirect
                    2,                              #logLevel (0 = ERRORS, 1 = ERRORS_AND_WARNINGS, 2 = ALL_INFO)
                    true,                           #isExecuteByPhase
                    false,                          #isResetOnFailure
                    true,                           #isRollbackAllowed
                    false,                          #isRollbackOnFailure
                    true,                           #isRebootIfRequired
                    true,                           #isCopyLockedFilesAfterReboot
                    true,                           #isStagingAfterSimulate
                    true                            #isCommitAfterStaging
                  ])

      job_db_key = result[:return_value]

      execute_against_targets(baa_base_url, session_id, job_db_key, targets, 'addNamedServerToJobByJobDBKey')

      job_db_key
    end

    def baa_soap_create_component_based_blpackage_deploy_job(baa_base_url, session_id, job_folder_id, job_name, package_db_key, targets)
      if targets.nil? || targets.empty?
        raise 'At least one component needs to be specified while creating a component based blpackage deploy job'
      end

      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', 'createComponentBasedDeployJob',
                  [
                    job_name,                       #deployJobName
                    job_folder_id,                  #groupId
                    package_db_key,                 #packageKey
                    1,                              #deployType (0 = BASIC, 1 = ADVANCED)
                    targets.first,                  #componentKey
                    true,                           #isSimulateEnabled
                    true,                           #isCommitEnabled
                    false,                          #isStagedIndirect
                    2,                              #logLevel (0 = ERRORS, 1 = ERRORS_AND_WARNINGS, 2 = ALL_INFO)
                    true,                           #isExecuteByPhase
                    false,                          #isResetOnFailure
                    true,                           #isRollbackAllowed
                    false,                          #isRollbackOnFailure
                    true,                           #isRebootIfRequired
                    true,                           #isCopyLockedFiles
                    true,                           #isStagingAfterSimulate
                    true,                           #isCommitAfterStaging
                    false,                          #isSingleDeployModeEnabled
                    false,                          #isSUMEnabled
                    0,                              #singleUserMode
                    0,                              #rebootMode
                    false,                          #isMaxWaitTimeEnabled
                    '30',                           #maxWaitTime
                    false,                          #isMaxAgentConnectionTimeEnabled
                    60,                             #maxAgentConnectionTime
                    false,                          #isFollowSymlinks
                    false,                          #useReconfigRebootAtEndOfJob
                    0                               #overrideItemReconfigReboot
                  ])

      job_db_key = result[:return_value]

      execute_against_targets(baa_base_url, session_id, job_db_key, targets, 'addComponentToJobByJobDBKey')

      job_db_key
    end

    def baa_soap_create_software_deploy_job(baa_base_url, session_id, job_folder_id, job_name, software_db_key, model_type, targets)
      if targets.nil? || targets.empty?
        raise 'At least one target needs to be specified while creating a software deploy job'
      end

      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', 'createSoftwareDeployJob',
                  [
                    job_name,                       #deployJobName
                    job_folder_id,                  #groupId
                    software_db_key,                #objectKey
                    model_type,                     #modelType
                    targets.first,                  #serverName
                    true,                           #isSimulateEnabled
                    true,                           #isCommitEnabled
                    false,                          #isStagedIndirect
                    2,                              #logLevel (0 = ERRORS, 1 = ERRORS_AND_WARNINGS, 2 = ALL_INFO)
                    false,                          #isResetOnFailure
                    true,                           #isRollbackAllowed
                    false,                          #isRollbackOnFailure
                    true,                           #isRebootIfRequired
                    true                            #isCopyLockedFilesAfterReboot
                  ])

      job_db_key = result[:return_value]

      execute_against_targets(baa_base_url, session_id, job_db_key, targets, 'addNamedServerToJobByJobDBKey')

      job_db_key
    end

    def baa_soap_create_file_deploy_job(baa_base_url, session_id, job_folder, job_name, source_file_list, destination_dir, targets)
      if targets.nil? || targets.empty?
        raise 'At least one target needs to be specified while creating a file deploy job'
      end

      source_files_arg = source_file_list.join(',')
      targets_arg = targets.join(',')

      result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id, 'FileDeployJob', 'createJobByServers',
                    [
                      job_name,                     #jobName
                      job_folder,                   #jobGroup
                      source_files_arg,             #sourceFiles
                      destination_dir,              #destination
                      false,                        #isPreserveSourceFilePaths
                      0,                            #numTargetsInParallel
                      targets_arg                   #targetServerNames
                    ], nil)

      result[:return_value]
    end

    def baa_soap_job_group_to_id(baa_base_url, session_id, job_folder)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'JobGroup', 'groupNameToId', [job_folder])
      result[:return_value]
    end

    def baa_soap_get_group_qualified_path(baa_base_url, session_id, group_type, group_id)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'Group', 'getAQualifiedGroupName',
                  [
                    get_model_type_to_model_type_id(group_type),    #groupType
                    group_id                                        #groupId
                  ])

      result[:return_value] # return qualified_name
    end

    def baa_soap_get_group_id_for_job(baa_base_url, session_id, job_key)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'Job', 'getGroupId',
                  [
                    job_key,    #jobKey
                  ])

      result[:return_value] # return group_id
    end

    def baa_soap_export_deploy_job_results(baa_base_url, session_id, job_folder, job_name, job_run_id)
      result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id,
                                                              'Utility', 'exportDeployRun',
                                                              [job_folder, job_name, job_run_id, '/tmp/test.csv'],
                                                              nil)
      get_attachment(result)
    end

    def baa_soap_export_snapshot_job_results(baa_base_url, session_id, job_folder, job_name, job_run_id, targets, export_format = 'CSV')
      csv_data = ''
      targets.each do | target |
        result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id,
                                                                'Utility', 'exportSnapshotRun',
                                                                [job_folder, job_name, job_run_id, 'null', 'null',
                                                                 target, get_export_format(export_format), export_format],
                                                                nil)
        if result && (result.has_key?(:attachment))
          attachment = result[:attachment]
          csv_data = csv_data + Base64.decode64(attachment) + "\n"
        end
      end
      csv_data
    end

    def baa_soap_export_nsh_script_job_results(baa_base_url, session_id, job_run_id)
      result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id,
                                                              'Utility', 'exportNSHScriptRun',
                                                              [job_run_id, '/tmp/test.csv'],
                                                              nil)
      get_attachment(result)
    end

    def baa_soap_export_compliance_job_results(baa_base_url, session_id, job_folder, job_name, job_run_id, export_format = 'CSV')
      result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id,
                                                              'Utility', 'exportComplianceRun',
                                                              ['null', 'null', 'null', job_folder, job_name, job_run_id,
                                                               get_export_format(export_format), export_format],
                                                              nil)
      get_attachment(result)
    end

    def baa_soap_export_audit_job_results(baa_base_url, session_id, job_folder, job_name, job_run_id)
      result = baa_soap_execute_cli_command_using_attachments(baa_base_url, session_id,
                                                              'Utility', 'simpleExportAuditRun',
                                                              [job_folder, job_name, job_run_id, '/tmp/test.csv', ''],
                                                              nil)
      get_attachment(result)
    end

    def baa_soap_db_key_to_rest_uri(baa_base_url, session_id, db_key)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'GenericObject', 'getRESTfulURI', [db_key])
      result[:return_value]
    end

    def baa_soap_map_server_names_to_rest_uri(baa_base_url, session_id, servers)
      targets = []
      servers.each do |server|
        result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'Server', 'getServerDBKeyByName', [server])
        targets << baa_soap_db_key_to_rest_uri(baa_base_url, session_id, result[:return_value])
      end
      targets
    end

    def baa_create_bl_package_from_component(baa_base_url, session_id, package_name, depot_group_id, component_key)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'BlPackage', 'createPackageFromComponent',
                  [
                    package_name,       #packageName
                    depot_group_id,     #groupId
                    true,               #bSoftLinked
                    false,              #bCollectFileAcl
                    false,              #bCollectFileAttributes
                    true,               #bCopyFileContents
                    false,              #bCollectRegistryAcl
                    component_key,      #componentKey
                  ])

      result[:return_value] # return bl_package_key
    end

    def baa_set_bl_package_property_value_in_deploy_job(baa_base_url, session_id, job_group_path, job_name, property, value_as_string, encrypted = false)
      command = encrypted ? 'setOverriddenParameterValueFromString' : 'setOverriddenParameterValue'
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', command,
                  [
                    job_group_path,     #groupName
                    job_name,           #jobName
                    property,           #parameterName
                    value_as_string     #valueAsString
                  ])

      result[:return_value] # return deploy_job
    end

#==================== FOR IUR 4.6 ====================
    def baa_clear_target_servers_from_job(baa_base_url, session_id, job_db_key)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'Job', 'clearTargetServers',
                                                          [
                                                              job_db_key,         #jobKey
                                                          ])

      result[:return_value] # job_db_key
    end

    def baa_add_target_servers_to_job(baa_base_url, session_id, job_db_key, targets)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'Job', 'addTargetServers',
                                                          [
                                                              job_db_key,         #jobKey
                                                              targets,            #serverNames
                                                          ])

      result[:return_value] # job_db_key
    end

    def baa_find_deploy_job(baa_base_url, session_id, group_name, job_name)
      begin
        result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', 'getDBKeyByGroupAndName',
                                                            [
                                                                group_name,         #groupName
                                                                job_name,           #jobName
                                                            ])

        result[:return_value]
      rescue Exception
        ''
      end
      # return job_db_key or ''
    end

    def baa_get_depot_object_key(baa_base_url, session_id, group_name, name, type)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DepotObject', 'getDBKeyByTypeStringGroupAndName',
                                                          [
                                                              type,                 #depotObjectTypeString
                                                              group_name,           #groupName
                                                              name,                 #depotObjectName
                                                          ])

      result[:return_value] # depot_object_key
    end

    def baa_get_depot_file_key(baa_base_url, session_id, group_name, file_name)
      baa_get_depot_object_key(baa_base_url, session_id, group_name, file_name, 'DEPOT_FILE_OBJECT')
    end

    def baa_get_bl_package_key(baa_base_url, session_id, group_name, name)
      baa_get_depot_object_key(baa_base_url, session_id, group_name, name, 'BLPACKAGE')
    end

    def baa_add_file_to_depot(baa_base_url, session_id, group_name, file_location, name)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DepotFile', 'addFileToDepot',
                                                          [
                                                              group_name,        #groupName
                                                              file_location,     #fileLocation
                                                              name,              #name
                                                              name,              #description
                                                          ])

      result[:return_value] # depot_object_key
    end

    def baa_group_name_to_id(baa_base_url, session_id, group_name)
      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DepotGroup', 'groupNameToId',
                                                          [
                                                              group_name,        #groupName
                                                          ])

      result[:return_value] # depot_group_id
    end

    def baa_create_bl_package_from_depot_files(baa_base_url, session_id, depot_file_keys, package_name, group_id, file_name_and_target_nsh_path_hash)
      name_path_str = String.new
      name_path_str_label = String.new
      file_name_and_target_nsh_path_hash.each do |name, nsh_path|
        name_path_str << '"' + name + ',' + nsh_path + '",'
        name_path_str_label << '"NAME,PATH",'
      end
      name_path_str.chop!
      name_path_str_label.chop!

      depot_file_keys_str = String.new
      sum_str = String.new
      reboot_str = String.new
      depot_file_keys.each do |depot_file_key|
        depot_file_keys_str << depot_file_key + ','
        sum_str << '"RebootAs,NotRequired",'
        reboot_str << '"AtJobEnd,NotRequired",'
      end
      depot_file_keys_str.chop!
      sum_str.chop!
      reboot_str.chop!

      result = baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'BlPackage', 'createPackageFromDepotObjectsEx',
                                                          [
                                                              depot_file_keys_str,              #depotObjectDBKeys
                                                              false,                        #isSoftLinked
                                                              package_name,                 #packageName
                                                              group_id,                     #packageGroupId
                                                              package_name,                 #packageDesc
                                                              name_path_str_label,          #propName
                                                              name_path_str,                #porpVal
                                                              sum_str,                      #SUM
                                                              reboot_str,                   #reboot
                                                          ])

      result[:return_value] # depot_object_key
    end

    def baa_add_string_property_to_blpackage(baa_base_url, session_id, package_name, group_path, property_name, default_value)
      baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'BlPackage', 'addLocalParameter',
                                                          [
                                                              package_name,             #blPackageName
                                                              group_path,               #groupName
                                                              property_name,            #propertyName
                                                              package_name,             #propertyDescription
                                                              'Primitive:/String',      #propertyType
                                                              true,                     #editable
                                                              false,                    #required
                                                              default_value,            #defaultValueString
                                                          ])
    end

    def baa_update_string_property_value_in_blpackage(baa_base_url, session_id, package_name, group_path, property_name, default_value)
      baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'BlPackage', 'setLocalParameterDefaultValue',
                                                 [
                                                     package_name,             #blPackageName
                                                     group_path,               #groupName
                                                     property_name,            #propertyName
                                                     default_value,             #defaultValueString
                                                 ])
    end
#==================== FOR IUR 4.6 ====================
    private

    @@cache = {}

    def compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, action_sub_url, sub_query = nil)
      url = "#{baa_base_url}#{action_sub_url}"
      url += "?username=#{baa_username}&password=#{baa_password}&role=#{baa_role}&version=#{rest_version}"
      url += sub_query unless sub_query.nil?
      url
    end

    def get_rest_response(url)
      response = build_rest_resource(url).get(accept: :json)
      parse_rest_response(response, 'querying', url)
    end

    def build_rest_resource(url)
      RestClient::Resource.new(URI.escape(url), get_rest_security_options) # resource
    end

    def parse_rest_response(response, action, url)
      response = JSON.parse(response)

      if response.has_key? 'ErrorResponse'
        raise "Error while #{action} to URL #{url}: #{response['ErrorResponse']['Error']}"
      end
      response
    end

    def parse_rest_status(response)
      h = {}
      response_status = response['StatusResponse']['Status']
      h['status'] = response_status['status']
      h['had_errors'] = response_status['hadErrors']
      h['had_warnings'] = response_status['hadWarnings']
      h['is_aborted'] = response_status['isAbort']
      h['job_run_url'] = response_status['targetURI']
      h
    end

    def execute_sub_query(baa_base_url, baa_username, baa_password, baa_role, query_url)
      delay = 0
      begin
        sleep(delay)
        url = compose_rest_url(baa_base_url, baa_username, baa_password, baa_role, query_url)
        response = get_rest_response(url)

        delay = 10
      end while (response.empty? || response['StatusResponse'].empty? || (response['StatusResponse']['Status']['status'] == 'RUNNING'))

      parse_rest_status(response)
    end

    def get_soap_client(baa_base_url, service_name, timeout = nil)
      Savon.client("#{baa_base_url}/services/BSA#{service_name}.wsdl") do |_, http|
        get_savon_security_injector.call(http.auth.ssl)
        http.read_timeout = timeout unless timeout.nil?
      end # return client
    end

    def store_cred(session_id, baa_username, baa_password)
      @@cache[session_id] = {username: baa_username, password: baa_password, real_session_id: session_id}
    end

    def store_role(session_id, baa_role)
      @@cache[session_id][:role] = baa_role
    end

    def store_new_session_id(session_id, new_session_id)
      @@cache[session_id][:real_session_id] = new_session_id
    end

    def get_cached_cred(session_id)
      raise "No cached credentials for session: #{session_id}" unless @@cache.key?(session_id)
      @@cache[session_id]
    end

    def get_real_session_id(session_id)
      get_cached_cred(session_id)[:real_session_id]
    end

    def execute_with_session_expiration_check(baa_base_url, session_id)
      begin
        yield
      rescue Savon::SOAP::Fault => e
        # re-raise exception if it's not a SessionCredentialExpiredException
        raise e unless session_credential_expired_exception?(e)
        # try to re-login (re-new session) if it's SessionCredentialExpiredException
        relogin(baa_base_url, session_id)

        yield
      end
    end

    def session_credential_expired_exception?(e)
      e.to_hash[:fault][:detail].key?(:session_credential_expired_exception)
    end

    def relogin(baa_base_url, session_id)
      cached_cred = get_cached_cred(session_id)
      new_session_id = baa_soap_login(baa_base_url, cached_cred[:username], cached_cred[:password], false)
      raise 'Could not re-login to BAA Cli Tunnel Service' if new_session_id.nil?
      store_new_session_id(session_id, new_session_id)

      baa_soap_assume_role(baa_base_url, cached_cred[:role], session_id)
    end

    def execute_against_targets(baa_base_url, session_id, job_db_key, targets, command)
      targets.drop(1).each do |t|
        baa_soap_execute_cli_command_by_param_list(baa_base_url, session_id, 'DeployJob', command, [job_db_key, t])
      end
    end

    def get_attachment(result)
      if result && (result.has_key?(:attachment))
        attachment = result[:attachment]
        Base64.decode64(attachment) # return csv_value
      else
        nil
      end
    end

    def get_export_format(export_format)
      "/tmp/test.#{(export_format == 'HTML') ? 'html' : 'csv'}"
    end

    def get_rest_security_options
      @rest_security_options ||= if SECURITY_MODE
                                   {
                                       ssl_ca_file: CERTIFICATE_PATH,
                                       ssl_ciphers: CIPHERS,
                                       verify_ssl:  OpenSSL::SSL::VERIFY_PEER
                                   }
                                 else
                                   {   verify_ssl:  OpenSSL::SSL::VERIFY_NONE }
                                 end
    end

    def get_savon_security_injector
      @soap_security_options_injector ||= if SECURITY_MODE
                                            Proc.new do |ssl|
                                              ssl.ca_cert_file = CERTIFICATE_PATH
                                              ssl.ciphers = CIPHERS
                                              ssl.verify_mode = :peer
                                            end
                                          else
                                            Proc.new do |ssl|
                                              ssl.verify_mode = :none
                                            end
                                          end
    end

  end
end
