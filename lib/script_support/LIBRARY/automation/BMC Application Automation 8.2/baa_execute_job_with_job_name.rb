###
#
# job_folder:
#   name: Job Folder
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: baa_job_folders
# job_name:
#   name: Job Name
#   type: in-text
#   position: A2:F2
# target_mode:
#   name: Target Mode
#   type: in-list-single
#   list_pairs: 0,Select|1,JobDefaultTargets|2,AlternateBAAComponents|3,MappedBAAComponents|4,AlternateBAAServers|5,MapFromBRPMServers
#   position: A3:B3
# targets:
#   name: Targets
#   type: in-external-multi-select
#   external_resource: baa_job_targets
#   position: A4:F4
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
# job_log_html:
#   name: Job Log HTML
#   type: out-file
#   position: A4:F4
###

require 'json'
require 'rest-client'
require 'uri'
require 'savon'
require 'base64'
require 'yaml'
require 'lib/script_support/baa_utilities'

params["direct_execute"] = true

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns

def get_target_url_prefix(target_mode)
  case target_mode
  when "4", "AlternateBAAServers"
    return "/id/SystemObject/Server/"
  when "2", "AlternateBAAComponents", "3", "MappedBAAComponents"
    return "/id/SystemObject/Component/"
  end
end

def export_job_results(session_id, job_folder, job_name, job_run_id, job_type, target_names)
  case job_type
  when "2", "PackageDeploy", "DEPLOY_JOB"
    return BaaUtilities.baa_soap_export_deploy_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id)
  when "3", "NSHScriptJob", "NSH_SCRIPT_JOB"
    return BaaUtilities.baa_soap_export_nsh_script_job_results(BAA_BASE_URL, session_id, job_run_id)
  when "4", "SnapshotJob", "SNAPSHOT_JOB"
    return BaaUtilities.baa_soap_export_snapshot_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id, target_names, "CSV")
  when "5", "ComplianceJob", "COMPLIANCE_JOB"
    return BaaUtilities.baa_soap_export_compliance_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id, "CSV")
  when "6", "AuditJob", "AUDIT_JOB"
    return BaaUtilities.baa_soap_export_audit_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id)
  end
  return nil
end

def export_html_job_results(session_id, job_folder, job_name, job_run_id, job_type, target_names)
  case job_type
  when "4", "SnapshotJob", "SNAPSHOT_JOB"
    return BaaUtilities.baa_soap_export_snapshot_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id, target_names, "HTML")
  when "5", "ComplianceJob", "COMPLIANCE_JOB"
    return BaaUtilities.baa_soap_export_compliance_job_results(BAA_BASE_URL, session_id, job_folder, job_name, job_run_id, "HTML")
  end
  return nil
end

def get_mapped_model_type(job_type)
  case job_type
  when "1", "FileDeploy"
    return "FILE_DEPLOY_JOB"
  when "2", "PackageDeploy"
    return "DEPLOY_JOB"
  when "3", "NSHScriptJob"
    return "NSH_SCRIPT_JOB"
  when "4", "SnapshotJob"
    return "SNAPSHOT_JOB"
  when "5", "ComplianceJob"
    return "COMPLIANCE_JOB"
  when "6", "AuditJob"
    return "AUDIT_JOB"
  end
end

  begin
    job_name = params["job_name"]
    job_group_id = params["job_folder"].split('|')[0]
    job_model_type = params["job_folder"].split('|')[2]
    job_group_rest_id = params["job_folder"].split('|')[1]

    job = BaaUtilities.find_job_from_job_folder(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_name, job_model_type, job_group_rest_id)
    job_url = job["uri"] rescue nil
    job_db_key = job["dbKey"] rescue nil
    job_type = job["modelType"] rescue nil
    raise "Could not find job: #{job_name} inside selected job folder." if job_url.nil?

    write_to("Job URL:"+job_url)

    if (job_type == "FILE_DEPLOY_JOB") || (job_type == "NSH_SCRIPT_JOB") || (job_type == "SNAPSHOT_JOB")

      if (params["target_mode"] == "2") || (params["target_mode"] == "AlternateBAAComponents") ||
        (params["target_mode"] == "3") || (params["target_mode"] == "MappedBAAComponents")
        raise "File deploy job cannot be run against components. It can run only against servers"
      end

    end

    session_id = BaaUtilities.baa_soap_login(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD)
    raise "Could not login to BAA Cli Tunnel Service" if session_id.nil?

    BaaUtilities.baa_soap_assume_role(BAA_BASE_URL, BAA_ROLE, session_id)

    targets = []
    target_names = []

    if (params["target_mode"] == "5") || (params["target_mode"] == "MapFromBRPMServers")
      servers = nil
      servers = params["servers"].split(",").collect{|s| s.strip} if params["servers"]
      raise "No BRPM servers found to map to BAA servers" if (servers.nil? || servers.empty?)

      target_names = servers

      targets = BaaUtilities.baa_soap_map_server_names_to_rest_uri(BAA_BASE_URL, session_id, servers)
    elsif params["targets"]
      targets = params["targets"].split(",")
      target_names = targets.collect{ |t| t.split("|")[0] }
      targets = targets.collect{ |t| "#{get_target_url_prefix(params["target_mode"])}#{t.split("|")[1]}" }
    end

    if (params["target_mode"] == "4") || (params["target_mode"] == "AlternateBAAServers") ||
      (params["target_mode"] == "5") || (params["target_mode"] == "MapFromBRPMServers")
      h = BaaUtilities.execute_job_against_servers(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_url, targets)
    elsif (params["target_mode"] == "2") || (params["target_mode"] == "AlternateBAAComponents") ||
      (params["target_mode"] == "3") || (params["target_mode"] == "MappedBAAComponents")
      h = BaaUtilities.execute_job_against_components(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_url, targets)
    elsif (params["target_mode"] == "1") || (params["target_mode"] == "JobDefaultTargets")
      h = BaaUtilities.execute_job(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_url)
    end

    raise "Could run specified job, did not get a valid response from server" if h.nil?

    execution_status = "_SUCCESSFULLY"
    execution_status = "_WITH_WARNINGS" if (h["had_warnings"] == "true")
    if (h["had_errors"] == "true")
      execution_status = "_WITH_ERRORS"
      write_to("Job Execution failed: Please check job logs for errors")
    end

    pack_response "job_status", h["status"] + execution_status

    job_run_url = h["job_run_url"]
    write_to("Job Run URL: #{job_run_url}")

    job_run_id = BaaUtilities.get_job_run_id(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_run_url)
    raise "Could not fetch job_run_id" if job_run_id.nil?

    job_result_url = BaaUtilities.get_job_result_url(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, job_run_url)

    if job_result_url
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
    else
      write_to("Could not fetch job_result_url, target based status not available")
    end

    # since issues DE86143 & DE88755 already fixed (fix implemented at baa_utilities.rb)
    # follow three lines of code no more required: baa_soap_login and baa_soap_assume_role
    # but it can leave as-is with-out any break to functionality
    session_id = BaaUtilities.baa_soap_login(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD)
    raise "Could not login to BAA Cli Tunnel Service" if session_id.nil?
    BaaUtilities.baa_soap_assume_role(BAA_BASE_URL, BAA_ROLE, session_id)

    job_folder_id = BaaUtilities.baa_soap_get_group_id_for_job(BAA_BASE_URL, session_id, job_db_key)
    job_folder_path = BaaUtilities.baa_soap_get_group_qualified_path(BAA_BASE_URL, session_id, "JOB_GROUP", job_folder_id)

    results_csv = export_job_results(session_id, job_folder_path, job_name, job_run_id, job_type, target_names)
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

    results_html = export_html_job_results(session_id, job_folder_path, job_name, job_run_id, job_type, target_names)
    if results_html
      baa_job_logs = File.join(params["SS_automation_results_dir"], "baa_job_logs")
      unless File.directory?(baa_job_logs)
        Dir.mkdir(baa_job_logs, 0700)
      end

      log_file_path = File.join(baa_job_logs, "#{job_run_id}.html")
      fh = File.new(log_file_path, "w")
      fh.write(results_html)
      fh.close

      pack_response "job_log_html", log_file_path
    end

  rescue Exception => e
    write_to("Operation failed: #{e.message}, Backtrace:\n#{e.backtrace.inspect}")
  end
