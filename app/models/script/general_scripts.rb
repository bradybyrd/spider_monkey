################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'fileutils'
require 'popen4'

class Script < ActiveRecord::Base

  def run_general_script(params, from_sync = false)
    #now send params hash - script_name, script_type, input_file = 'none'
    argument_string = "_SS_INPUTFILE='#{params["SS_input_file"]}'"
    if params["direct_execute"].nil?
      command = "#{RUBY_PATH} -S cap -f '#{params["SS_script_file"]}'" #" execute"
    else
      command = "#{RUBY_PATH} '#{params["SS_script_file"]}'"
    end
    @delay_log.puts "Executing script: #{command}" if @delay_log
    msg = "#{params["SS_script_target"] == "general" ? "[General Script]" : "[General Script]"} - Running command: \n#{command}"
    AutomationCommon.append_output_file(params, msg)
    AutomationCommon.append_output_file(params,AutomationCommon.output_separator("RESULTS"))
    logger.info "=== Automation Command: #{command}"
    script_result, results_err, results_out = "", "", ""
    status = IO::popen4(command) do |pid, stdin, stdout, stderr|
      script_result += "[STDOUT]\n"
      stdin.close
      [
        Thread.new(stdout) {|stdout_io|
          stdout_io.each_line do |l|
            results_out += l
          end
          stdout_io.close
        },

        Thread.new(stderr) {|stderr_io|
          stderr_io.each_line do |l|
            results_err += l
          end
        }
      ].each( &:join )
      params["SS_process_pid"] = pid
    end
    exitstatus = status.respond_to?(:exitstatus) ? status.exitstatus : $?.exitstatus
    results_out += "\n[EXIT STATUS: #{exitstatus}]\n"
    results_out += exit_code_failure(params)
    results_err = "\n[STATUS: " + results_err + "]" if results_err.length > 4
    script_result += results_err
    script_result += results_out
    AutomationCommon.append_output_file(params, "\nProcess ID: #{params["SS_process_pid"]}\n")
    AutomationCommon.append_output_file(params, "\n[STDERR]\n#{results_err}\n") if results_err.length > 4
#    AutomationCommon.append_output_file(params, "\n#{results_out}\n")
    script_result += "\n[Script output written to: #{params["SS_output_file"]}]\n"
    logger.info "[SSH-Capistrano] - Command returned [#{script_result}]\n"
    #FIXME:Unrequired code portion;should be removed
    if false & params.has_key?("SS_job_run_id") # Running in background
      jr = JobRun.find(params["SS_job_run_id"])
      jr.stdout = script_result
      jr.stderr = err
    end
    #ActiveRecord::Base.establish_connection RAILS_ENV.to_sym
    script_result
  end

  private

    def default_path
      AutomationCommon::DEFAULT_AUTOMATION_SUPPORT_PATH
    end

    def old_error_in?(result)
      #(result =~ /^\s*\[err ::[^\]]*\]/).nil?
      !(result =~ /\[ERROR: /).nil?
    end

end
