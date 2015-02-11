###
#
# job_folder:
#   name: Job Folder
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: baa_job_folders
# deploy_job_name:
#   name: Deploy Job Name
#   position: A2:B2
#   required: yes
# depot_object_type:
#   name: Depot Object Type
#   type: in-list-single
#   list_pairs: 0,Select|1,BLPackage|2,AixPatch|3,AixPackage|4,HPProduct|5,HPBundle|6,HPPatch|7,LinuxRPM|8,SolarisPatch|9,SolarisPackage|10,WindowsHotfix|11,WindowsSP|12,WindowsMSI|13,InstallShield
#   position: A3:B3
#   required: yes
# depot_object:
#   name: Package
#   type: in-external-single-select
#   external_resource: baa_depot_objects
#   position: A4:F4
# target_mode:
#   name: Target Mode
#   type: in-list-single
#   list_pairs: 0,Select|2,AlternateBAAComponents|3,MappedBAAComponents|4,AlternateBAAServers|5,MapFromBRPMServers
#   position: A5:B5
#   required: yes
# targets:
#   name: Targets
#   type: in-external-multi-select
#   external_resource: baa_job_targets
#   position: A6:F6
# execute_immediately:
#   name: Execute Immediately
#   type: in-list-single
#   list_pairs: 1,Yes|2,No
#   position: A7:B7
# job_status:
#   name: Job Status
#   type: out-text
#   position: A1:C1
# target_status:
#   name: Target Status
#   type: out-table
#   position: A2:F2
# job_log:
#   name: Job Log
#   type: out-file
#   position: A3:F3
###

require 'lib/script_support/baa_utilities'
require 'yaml'
require 'uri'

params["direct_execute"] = true

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns


def get_mapped_model_type(depot_object_type)
  mapped_model_type = ""
  case depot_object_type
  when "1", "BLPackage"
    mapped_model_type = "BLPACKAGE"
  when "2", "AixPatch"
    mapped_model_type = "AIX_PATCH_INSTALLABLE"
  when "3", "AixPackage"
    mapped_model_type = "AIX_PACKAGE_INSTALLABLE"
  when "4", "HPProduct"
    mapped_model_type = "HP_PRODUCT_INSTALLABLE"
  when "5", "HPBundle"
    mapped_model_type = "HP_BUNDLE_INSTALLABLE"
  when "6", "HPPatch"
    mapped_model_type = "HP_PATCH_INSTALLABLE"
  when "7", "LinuxRPM"
    mapped_model_type = "RPM_INSTALLABLE"
  when "8", "SolarisPatch"
    mapped_model_type = "SOLARIS_PATCH_INSTALLABLE"
  when "9", "SolarisPackage"
    mapped_model_type = "SOLARIS_PACKAGE_INSTALLABLE"
  when "10", "WindowsHotfix"
    mapped_model_type = "HOTFIX_WINDOWS_INSTALLABLE"
  when "11", "WindowsSP"
    mapped_model_type = "SERVICEPACK_WINDOWS_INSTALLABLE"
  when "12", "WindowsMSI"
    mapped_model_type = "MSI_WINDOWS_INSTALLABLE"
  when "13", "InstallShield"
    mapped_model_type = " INSTALLSHIELD_WINDOWS_INSTALLABLE"
  end
  mapped_model_type
end

def get_targets_for_job(params)
  targets = []
  if (params["target_mode"] == "4") || (params["target_mode"] == "AlternateBAAServers")
    if params["targets"]
      targets = params["targets"].split(",")
      targets = targets.collect{ |t| t.split("|")[0] }
    end
  elsif (params["target_mode"] == "5") || (params["target_mode"] == "MapFromBRPMServers")
    targets = params["servers"].split(",").collect {|s| s.strip}  if params["servers"]
  elsif (params["target_mode"] == "2" ) || (params["target_mode"] == "AlternateBAAComponents") ||
        (params["target_mode"] == "3" ) || (params["target_mode"] == "MappedBAAComponents")

    if params["targets"]
      targets = params["targets"].split(",")
      targets = targets.collect{ |t| t.split("|")[2] }
    end
  end
  targets
end

  begin
    if (params["target_mode"] == "2" ) || (params["target_mode"] == "AlternateBAAComponents" ) ||
      (params["target_mode"] == "3" ) || (params["target_mode"] == "MappedBAAComponents" )
      unless (params["depot_object_type"] == "1") || (params["depot_object_type"] == "BLPackage")
        raise "Deployment against components is not supported with Software Deploy. Only BLPackage is Supported"
      end
    end

    package_params = params["depot_object"].split("|")
    package_name = package_params[0]
    package_url = package_params[1]
    package_db_key = package_params[2]

    session_id = BaaUtilities.baa_soap_login(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD)
    raise "Could not login to BAA Cli Tunnel Service" if session_id.nil?

    BaaUtilities.baa_soap_assume_role(BAA_BASE_URL, BAA_ROLE, session_id)

    job_group_id = params["job_folder"].split('|')[0]

    targets = get_targets_for_job(params)
    job_db_key = nil

    if (params["depot_object_type"] == "1") || (params["depot_object_type"] == "BLPackage")
      if (params["target_mode"] == "4") || (params["target_mode"] == "AlternateBAAServers") ||
        (params["target_mode"] == "5") || (params["target_mode"] == "MapFromBRPMServers")

        job_db_key = BaaUtilities.baa_soap_create_blpackage_deploy_job(BAA_BASE_URL, session_id, job_group_id, params["deploy_job_name"], package_db_key, targets)

        begin
          job_group_path = BaaUtilities.baa_soap_get_group_qualified_path(BAA_BASE_URL, session_id, "JOB_GROUP", job_group_id)
          raise "Job group path not found" if job_group_path.nil?

          params.each_pair do |k,v|
            if (k =~ /^#{"BAA_"}/) && !v.blank?
              write_to("Setting value for property: #{k.gsub("BAA_", "")}")
              unless params["#{k}_encrypt"].blank?
                encrypted = true
                params.reject!{ |key| key == "#{k}_encrypt"}
              end
              BaaUtilities.baa_set_bl_package_property_value_in_deploy_job(BAA_BASE_URL, session_id, job_group_path, params["deploy_job_name"], k.gsub("BAA_", ""), v, encrypted)
            end
          end

        rescue Exception => e1
          raise "Could not set property values: #{e1.message}"
        end

      elsif (params["target_mode"] == "2" ) || (params["target_mode"] == "AlternateBAAComponents") ||
        (params["target_mode"] == "3" ) || (params["target_mode"] == "MappedBAAComponents")

        job_db_key = BaaUtilities.baa_soap_create_component_based_blpackage_deploy_job(BAA_BASE_URL, session_id, job_group_id,
                            params["deploy_job_name"], package_db_key, targets)
      end
    else
      job_db_key = BaaUtilities.baa_soap_create_software_deploy_job(BAA_BASE_URL, session_id, job_group_id, params["deploy_job_name"], package_db_key,
                            get_mapped_model_type(params["depot_object_type"]), targets)
    end

    raise "Could not create Deploy job" if job_db_key.nil?

    if (params["execute_immediately"] == "1") || (params["execute_immediately"] == "Yes")
      job_url = BaaUtilities.baa_soap_db_key_to_rest_uri(BAA_BASE_URL, session_id, job_db_key)
      raise "Could not fetch REST URI for job: #{job_db_key}" if job_url.nil?

      h = BaaUtilities.execute_job(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_url)
      raise "Could run specified job, did not get a valid response from server" if h.nil?

      execution_status = "_SUCCESSFULLY"
      execution_status = "_WITH_WARNINGS" if (h["had_warnings"] == "true")
      if (h["had_errors"] == "true")
        execution_status = "_WITH_ERRORS"
        write_to("Job Execution failed: Please check job logs for errors")
      end

      pack_response "job_status", h["status"] + execution_status

      job_run_url = h["job_run_url"]
      job_run_id = BaaUtilities.get_job_run_id(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_run_url)
      raise "Could not fetch job_run_id" if job_run_id.nil?

      job_result_url = BaaUtilities.get_job_result_url(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_run_url)
      raise "Could not fetch job_result_url" if job_result_url.nil?

      h = BaaUtilities.get_per_target_results(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_result_url)
      if h
        table_data = [['', 'Target Type', 'Name', 'Had Errors?', 'Had Warnings?', 'Need Reboot?', 'Exit Code']]
        target_count = 0
        h.each_pair do |k3, v3|
          v3.each_pair do |k1, v1|
            table_data << ['', k3, k1, v1['HAD_ERRORS'], v1['HAD_WARNINGS'], v1['REQUIRES_REBOOT'], v1['EXIT_CODE*']]
            target_count = target_count + 1
          end
        end
        pack_response "target_status", {:totalItems => target_count, :perPage => '10', :data => table_data }
      end

      # since issues DE86143 & DE88755 already fixed (fix implemented at baa_utilities.rb)
      # follow three lines of code no more required: baa_soap_login and baa_soap_assume_role
      # but it can leave as-is with-out any break to functionality
      session_id = BaaUtilities.baa_soap_login(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD)
      raise "Could not login to BAA Cli Tunnel Service" if session_id.nil?
      BaaUtilities.baa_soap_assume_role(BAA_BASE_URL, BAA_ROLE, session_id)

      job_group_path = BaaUtilities.baa_soap_get_group_qualified_path(BAA_BASE_URL, session_id, "JOB_GROUP", job_group_id)

      results_csv = BaaUtilities.baa_soap_export_deploy_job_results(BAA_BASE_URL, session_id, job_group_path, params["deploy_job_name"], job_run_id)
      if results_csv
        baa_job_logs = File.join(params["SS_automation_results_dir"], "baa_job_logs")
        unless File.directory?(baa_job_logs)
          Dir.mkdir(baa_job_logs, 0700)
        end

        log_file_path = File.join(baa_job_logs, "#{job_run_id}.log")
        fh = File.new(log_file_path, "w")
        fh.write(results_csv)
        fh.close

        pack_response "job_log", log_file_path
      else
        write_to("Could not fetch job results...")
      end
    end

  rescue Exception => e
    write_to("Operation failed: #{e.message}, Backtrace:\n#{e.backtrace.inspect}")
  end
