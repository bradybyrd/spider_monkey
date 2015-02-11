require 'json'
require 'rest-client'
require 'uri'
require 'base64'
require 'xmlsimple'
require 'builder'

module RlmUtilities
  class << self

    #############################Getter methods#############################################

    ### define methods
    ### get_all_packages(rlm_base_url, rlm_username, rlm_password)
    ### get_all_repos(rlm_base_url, rlm_username, rlm_password)
    ### get_all_routes(rlm_base_url, rlm_username, rlm_password)
    ### get_all_environments(rlm_base_url, rlm_username, rlm_password)

    subject_items = { packages:     'package list',
                      repos:        ['repo list', 'Ready'],
                      routes:       'route list',
                      environments: 'environment list'
    }

    subject_items.each do |s, v|
      define_method "get_all_#{s}" do |rlm_base_url, rlm_username, rlm_password|
        get_all_items_list(rlm_base_url, rlm_username, rlm_password, *v)
      end
    end

    ### define methods
    ### get_package_instances(rlm_base_url, rlm_username, rlm_password, package = nil)
    ### get_repo_instances(rlm_base_url, rlm_username, rlm_password, package = nil)
    ### get_package_properties(rlm_base_url, rlm_username, rlm_password, package = nil)
    ### get_package_content_references(rlm_base_url, rlm_username, rlm_password, package = nil)

    subject_package_items = { package_instances:          ['instance package list', 'Ready'],
                              repo_instances:             ['instance repo list', 'Ready', nil, '0'],
                              package_properties:         ['package property list'],
                              package_content_references: ['package reference list']
    }

    subject_package_items.each do |s, v|
      define_method "get_#{s}" do |rlm_base_url, rlm_username, rlm_password, package = nil|
        get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, package, *v)
      end
    end

    ### define methods
    ### get_package_instance_properties(rlm_base_url, rlm_username, rlm_password, instance = nil)
    ### get_repo_instance_properties(rlm_base_url, rlm_username, rlm_password, instance = nil)
    ### get_repo_properties(rlm_base_url, rlm_username, rlm_password, instance = nil)
    ### get_package_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance = nil)
    ### get_repo_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance = nil)

    subject_instance_items = { package_instance_properties:         'instance property list',
                               repo_instance_properties:            'instance property list',
                               repo_properties:                     'repo property list',
                               package_instance_content_references: 'instance artifact list',
                               repo_instance_content_references:    'instance artifact list'
    }

    subject_instance_items.each do |s, v|
      define_method "get_#{s}" do |rlm_base_url, rlm_username, rlm_password, instance = nil|
        get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, instance, v)
      end
    end


    def get_root_repo_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance = nil)
      repo_instance_references = get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, instance, 'instance artifact list', nil, 'tree')
      #return reference_name
      repo_instance_references ? parse_repo_references(repo_instance_references) : {}
    end

    def get_root_repo_content_references(rlm_base_url, rlm_username, rlm_password, instance = nil)
      repo_instance_references = get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, instance, 'repo artifact list', nil, 'tree')
      #return reference_name
      repo_instance_references ? parse_repo_references(repo_instance_references) : {}
    end

    def parse_repo_references(repo_references)
      reference_name = {}
      repo_references.each do |hsh|
        hsh.each do |ref_name, reference_id|
          next if ref_name.nil?
          reference_name[ref_name.split('=')[0]] = "#{reference_id}=#{ref_name.split('=')[1]}"
        end
      end
      reference_name
    end

    def get_package_instance_status(rlm_base_url, rlm_username, rlm_password, package_instance)
      get_status(rlm_base_url, rlm_username, rlm_password, 'instance status', package_instance)
    end

    def get_repo_instance_status(rlm_base_url, rlm_username, rlm_password, package_instance)
      get_status(rlm_base_url, rlm_username, rlm_password, 'instance status', package_instance)
    end

    def get_deploy_status(rlm_base_url, rlm_username, rlm_password, deploy_instance)
      get_status(rlm_base_url, rlm_username, rlm_password, 'deploy status', deploy_instance)
    end

    # def get_package_instance_environments(rlm_base_url, rlm_username, rlm_password, package_instance)
    #   get_environments_by(package_instance, rlm_base_url, rlm_username, rlm_password, "instance environment list")
    # end

    def get_route_environments(rlm_base_url, rlm_username, rlm_password, route, request_environment)
      get_environments_by(route, rlm_base_url, rlm_username, rlm_password, 'route environment list', request_environment)
      # route_type = get_route_type(rlm_base_url, rlm_username, rlm_password, "route type", route)
      # unless route_type == "Strict"
      #   get_environments_by(route, rlm_base_url, rlm_username, rlm_password, "route environment list")
      # else
      #   []
      # end
    end

    def get_environment_channels(rlm_base_url, rlm_username, rlm_password, environment_id)
      return [] if environment_id.blank?
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              'environment channel list', [environment_id])

      response = xml_to_hash_response['result'][0]['response']
      return [] if response.blank?

      total_items = 0
      table_data = [ ['', 'Channel Name'] ]

      response.each { |reference|
        table_data << [reference['id'], reference['value']]
        total_items = total_items + 1
      }

      { totalItems: total_items, perPage: 10, data: table_data }
    end

    ######## Looks like next method is unused###########
    def get_route_type(rlm_base_url, rlm_username, rlm_password, command, route)
      get_status(rlm_base_url, rlm_username, rlm_password, command, route)
    end

    def get_all_instance_routes(rlm_base_url, rlm_username, rlm_password, instance)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              'instance route get', [instance])
      response = {}
      hash_response = xml_to_hash_response['result'][0]['response']

      return [] if hash_response.first == 'No route assigned to that instance'

      hash_response.map{|hsh| response[hsh['value']] = hsh['id'] }
      [response]
    end

    def get_all_items_list(rlm_base_url, rlm_username, rlm_password, command, argument = nil)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [argument])

      # This should return response in the following format
      # [{"id"=>"1", "value"=>"Sample File Deploy Project"}, {"id"=>"2", "value"=>"package 2"}]
      response = {}
      hash_response = xml_to_hash_response['result'][0]['response']
      if command == 'package list'
        hash_response.map{|hsh| response[hsh['value']] = "#{hsh['id']}*#{hsh['value']}" }
      else
        hash_response.map{|hsh| response[hsh['value']] = hsh['id'] }
      end

      [response]
    end

    def get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, package, command, status = nil, type = nil, frozen = nil)
      raise 'No valid package name/ID provided.' if package.nil?
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [package, status, frozen])

      # separate resource automation output for table type arguments
      if ['package reference list', 'instance artifact list'].include?(command) && type.nil?
        display_output_as_table_format(xml_to_hash_response, 'Reference Name', 'Reference URL')
      elsif ['package property list', 'instance property list', 'repo property list'].include?(command) && type.nil?
        display_output_as_table_format(xml_to_hash_response, 'Property Name', 'Value set in Q')
      else
        response = {}
        hash_response = xml_to_hash_response['result'][0]['response']
        hash_response.map{|hsh| response[hsh['value']] = hsh['id'] }

        [response]
      end
    end

    # Here package_instance_id_or_name could be only id OR package_name:instance_name
    def get_status(rlm_base_url, rlm_username, rlm_password, command, pack_inst_id_or_name)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [pack_inst_id_or_name])

      hash_response = xml_to_hash_response['result'][0]['response']
      # hash_response = [{"id"=>"74", "value"=>"Error:new-ip-package:0.0.0.22"}]

      instance_status = hash_response.first['value'].split(':').first rescue nil
      # instance_status = "Error"

      instance_status
    end

    def get_environments_by(entity_argument, rlm_base_url, rlm_username, rlm_password, command, request_environment)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [entity_argument])

      environments = {}
      hash_response = xml_to_hash_response['result'][0]['response']
      hash_response.map{|hsh|
        if hsh['value'] != nil && hsh['id'] != nil
          if hsh['value'] == request_environment
            env_val = "#{request_environment}(inherited from request)"
            env_id = "#{hsh['id']}-inherited"
          else
            env_val = hsh['value']
            env_id = hsh['id']
          end
          environments[env_val] = env_id
        end
      }
      [environments]
    end

    def get_logs(rlm_base_url, rlm_username, rlm_password, object_id, command, log_format_str = '')
      log_format = log_format_str == 'New Format' ? 1 : 0
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [object_id, log_format])
      hash_response = xml_to_hash_response['result'][0]['response']
      hash_response.first.empty? ? nil : hash_response.try(:to_yaml)
    end

    def get_instance_logs(rlm_base_url, rlm_username, rlm_password, package_instance_id, command)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [package_instance_id])

      hash_response = xml_to_hash_response['result'][0]['response']
      hash_response.first.empty? ? nil : hash_response.try(:to_yaml)
    end

    def get_deployment_logs(rlm_base_url, rlm_username, rlm_password, deployment_id, log_format_str = '')
      log_format = log_format_str == 'New Format' ? 1 : 0
      deployment_log = ''
      deploy_proc_hash_response = get_hash_response(rlm_base_url, rlm_username, rlm_password, deployment_id, 'deploy processes')
      process_ids = []
      return nil if deploy_proc_hash_response.nil?
      deploy_proc_hash_response.map{|process| process_ids << process['id']}
      return nil if process_ids.blank?
      activity_ids = []
      process_ids.each do |process_id|
        proc_activity_hash_response = get_hash_response(rlm_base_url, rlm_username, rlm_password, process_id, 'process activity list')
        proc_activity_hash_response.map{|activity| activity_ids << activity['id']} unless proc_activity_hash_response.nil?
      end
      return nil if activity_ids.blank?
      task_ids = []
      activity_ids.each do |activity_id|
        proc_task_hash_response = get_hash_response(rlm_base_url, rlm_username, rlm_password, activity_id, 'process task list')
        proc_task_hash_response.map{|task| task_ids << task['id']} unless proc_task_hash_response.nil?
      end
      return nil if task_ids.blank?
      task_ids.each do |task_id|
        proc_task_list_hash_response = get_hash_response(rlm_base_url, rlm_username, rlm_password, task_id, 'process task log', log_format)
        unless proc_task_list_hash_response.nil?
          deployment_log += proc_task_list_hash_response.try(:to_yaml)
          deployment_log += "\n\n"
        end
      end
      deployment_log.empty? ? nil : deployment_log
    end

    def get_hash_response(rlm_base_url, rlm_username, rlm_password, deployment_id, command, log_format = nil)
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [deployment_id, log_format])

      hash_response = xml_to_hash_response['result'][0]['response']
      hash_response.first.empty? ? nil : hash_response
    end

    #############################Setter methods#############################################

    # Accept package as id or package name
    def create_package_instance(rlm_base_url, rlm_username, rlm_password, package, locked_status='No', instance_name = nil)
      raise 'No valid package name/ID provided.' if package.nil?
      command = locked_status == 'No' ? 'instance create package' : 'instance create locked package'
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [package, instance_name])

      xml_to_hash_response['result'][0]['response']
    end

    def create_repo_instance(rlm_base_url, rlm_username, rlm_password, repo, locked_status='No', instance_name = nil)
      raise 'No valid Repo name/ID provided.' if repo.nil?
      command = locked_status == 'No' ? 'instance create repo' : 'instance create locked repo'
      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command, [repo, instance_name])

      xml_to_hash_response['result'][0]['response']
    end

    def deploy_package_instance(rlm_base_url, rlm_username, rlm_password, instance, route, environment, channels = nil)

      command = ['instance deploy', instance, route]
      command << environment if environment.present?
      command << "-c #{channels.gsub(/,/, ' ')}" if channels.present?

      xml_to_hash_response = send_xml_request(rlm_base_url, rlm_username, rlm_password,
                                              command.join(' '), nil)

      hash_response = xml_to_hash_response['result'][0]['response']
      hash_response.first.empty? ? nil : hash_response[0]['id']
    end

    #################################Convertors####################################################

    def display_output_as_table_format(hash_response, table_header_1, table_header_2)
      response = hash_response['result'][0]['response']
      total_items = 0
      per_page = 10
      table_data =[ ['', table_header_1, table_header_2] ]
      response = response.first.empty? ? nil : response
      if response.nil?
        return []
        # table_data << ['', '', '']
      else
        response.each do |ref|
          name = ref['value'].split('=').first
          url = ref['value'].split('=').last
          # id = ref["id"]
          id = name
          table_data << [id, name, url]
          total_items = total_items + 1
        end
      end
      { totalItems: total_items, perPage: per_page, data: table_data }
    end

    def rlm_set_q_property_value(rlm_base_url, rlm_username, rlm_password, entity, command, property_name, property_value, encrypt = nil)
      send_xml_request(rlm_base_url, rlm_username, rlm_password, command,
                       [entity, property_name, "\"#{property_value.gsub("\"", "\"\"")}\"", encrypt])

      true # Property update successful
    end

    def send_xml_request(rlm_base_url, rlm_username, rlm_password, command, arguments = nil)
      url = "#{rlm_base_url}/index.php/api/processRequest.xml"
      request_doc_xml = Builder::XmlMarkup.new
      request_doc_xml.q(auth: "#{rlm_username} #{rlm_password}") do
        request_doc_xml.request(command: command) do
          arguments.each { |arg|
              request_doc_xml.arg("#{arg}") if arg.present?
          } unless arguments.nil?
        end
      end

      xml_response = RestClient.post(url, request_doc_xml, content_type: :xml, accept: :xml)
      xml_to_hash_response = XmlSimple.xml_in(xml_response)

      if xml_to_hash_response['result'][0]['rc'] != '0' || xml_to_hash_response['result'][0]['message'] != 'Ok'
        raise "Error while posting to URL #{url}: #{xml_to_hash_response['result'][0]['message']}"
      end

      xml_to_hash_response
    end

    def write_logs_to_file(instance_id, result_dir, instance_logs)
      rlm_instance_logs = File.join(result_dir, 'rlm_instance_logs')
      unless File.directory?(rlm_instance_logs)
        Dir.mkdir(rlm_instance_logs, 0700)
      end

      log_file_path = File.join(rlm_instance_logs, "#{instance_id}.txt")
      fh = File.new(log_file_path, 'w')
      fh.write(instance_logs)
      fh.close

      log_file_path
    end
  end
end
