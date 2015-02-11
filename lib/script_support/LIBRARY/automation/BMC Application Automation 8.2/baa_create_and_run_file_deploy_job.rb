###
#
# job_folder:
#   name: Job Folder
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: baa_job_folders
# job_name:
#   name: Job Name
#   position: A2:C2
#   required: yes
# file_1:
#   name: File 1
#   type: in-file
#   position: A3:F3
# file_2:
#   name: File 2
#   type: in-file
#   position: A4:F4
# brpm_enrolled_name:
#   name: BRPM enrolled name
#   type: in-text
#   position: A5:C5
# nsh_paths:
#   name: NSH Paths to files(comma delimited fully qualified NSH paths)
#   type: in-text
#   position: A6:F6
# destination_dir:
#   name: Destination Directory (NSH Path local to a target host)
#   position: A7:C7
#   required: yes
# target_mode:
#   name: Target Mode
#   type: in-list-single
#   list_pairs: 0,Select|4,AlternateBAAServers|5,MapFromBRPMServers
#   position: A8:B8
#   required: yes
# targets:
#   name: Targets
#   type: in-external-multi-select
#   external_resource: baa_job_targets
#   position: A9:F9
# execute_immediately:
#   name: Execute Immediately
#   type: in-list-single
#   list_pairs: 1,Yes|2,No
#   position: A10:B10
# job_status:
#   name: Job Status
#   type: out-text
#   position: A1:C1
# target_status:
#   name: Target Status
#   type: out-table
#   position: A2:F2
#
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

def get_attachment_nsh_path(brpm_host_name, attachment_local_path)
  if attachment_local_path[1] == ":"
    attachment_local_path[1] = attachment_local_path[0]
    attachment_local_path[0] = '/'
  end
  attachment_local_path = attachment_local_path.gsub(/\\/, "/")
  "//#{brpm_host_name}#{attachment_local_path}"
end

  begin
    session_id = BaaUtilities.baa_soap_login(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD)
    raise "Could not login to BAA Cli Tunnel Service" if session_id.nil?

    BaaUtilities.baa_soap_assume_role(BAA_BASE_URL, BAA_ROLE, session_id)

    job_group_id = params["job_folder"].split('|')[0]
    job_group_path = BaaUtilities.baa_soap_get_group_qualified_path(BAA_BASE_URL, session_id, "JOB_GROUP", job_group_id)

    targets = get_targets_for_job(params)
    job_db_key = nil

    files_to_deploy = []
    files_to_deploy << get_attachment_nsh_path(params["brpm_enrolled_name"], params["file_1"]) if (params["file_1"] && !params["file_1"].empty?)
    files_to_deploy << get_attachment_nsh_path(params["brpm_enrolled_name"], params["file_2"]) if (params["file_2"] && !params["file_2"].empty?)

    if params["nsh_paths"]
      params["nsh_paths"].split(',').each do |path|
        files_to_deploy << path
      end
    end

    job_db_key = BaaUtilities.baa_soap_create_file_deploy_job(BAA_BASE_URL, session_id, job_group_path, params["job_name"],
                files_to_deploy, params["destination_dir"], targets)
    raise "Could not create file deploy job. Did not get a valid db key back" if job_db_key.nil?

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
    end

  rescue Exception => e
    write_to("Operation failed: #{e.message}, Backtrace:\n#{e.backtrace.inspect}")
  end


