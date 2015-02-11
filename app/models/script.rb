################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'fileutils'
require 'net/http'
require 'uri'
require 'rubygems'

class Script < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt
  include SharedScript
  include ObjectState

  # set_inheritance_column do
  #   "script_" + original_inheritance_column
  # end

  paginate_alphabetically :by => :name
  ARGUMENT_REGEX = /\s*^###\r?\n(.+?)(\r?\n)+?\s*^###\r?/m

  SUPPORTED_AUTOMATION_INPUT_DATA_TYPES = ["in-text", "in-int", "in-decimal", "in-email", "in-url", "in-file", "in-date",
          "in-time", "in-list-single", "in-list-multi", "in-user-single-select", "in-user-multi-select", "in-server-single-select",
          "in-server-multi-select", "in-external-single-select", "in-external-multi-select", "in-datetime"]

  SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES  = ["out-text", "out-email", "out-url", "out-file", "out-date", "out-time", "out-list", "out-table",
          "out-user-single", "out-user-multi", "out-server-single", "out-server-multi", "out-external-single",
          "out-external-multi"]

  SUPPORTED_DATA_TYPES = SUPPORTED_AUTOMATION_INPUT_DATA_TYPES + SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES

  DEFAULT_SCRIPTS_PATH = "#{Rails.root}/public/capistrano_scripts"

  concerned_with :hudson_scripts
  concerned_with :general_scripts
  concerned_with :script_argument_validations

  has_many :arguments, :class_name => 'ScriptArgument', :foreign_key => 'script_id', :dependent => :destroy
  has_many :steps

  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}


  # adding this to support reuse of the query table for history on external resource automation runs
  # to store the plan, project_server, script_id, and query_details for each run in order to quickly
  # be able to rerun them from a menu
  has_many :queries, :dependent => :destroy
  belongs_to :project_server, :foreign_key => 'integration_id'
  has_one :application_component_mapping

  validates :name,
            :presence => true,
            :uniqueness => true
  validates :content, :presence => true

  validates :unique_identifier,
            :presence => {:if => Proc.new { |a| a.automation_type == "ResourceAutomation" }, :message =>  "^Resource Id can't be blank" }

  before_save :check_content, :update_owner, :set_automation_category_type #,:set_script_type
  
  after_save :update_arguments, :update_position_arguments

  # after_destroy :delete_content
  before_destroy :fails_if_in_use, :clear_scripts_when_not_in_use

  scope :sorted, order('name')
  scope :resource_automations, where(:automation_type => "ResourceAutomation")
  scope :active, where(arel_table[:aasm_state].not_eq('draft').and(arel_table[:aasm_state].not_eq('archived_state')))


  # there was some initial confusion over whether ticketing queries would be resource automations
  # or regular automations, but since they use other resource automations, the decision I think
  # will be that they are simple Automations -- then we need to expose the :maps_to control or mack
  # a new type that will allow us to pull these out.
  scope :ticketing_automations, where(:automation_type => "ResourceAutomation", :maps_to => "Ticket")
  scope :component_mapping_automations, where(:automation_type => "ResourceAutomation", :maps_to => "Component")

  attr_accessor :template_id, :template_script

  attr_accessible :name, :type, :description, :content, :integration_id, :tag_id, :authentication,
                  :automation_category, :automation_type, :created_by, :updated_by,
                  :template_script, :integration_id, :job, :unique_identifier, :render_as, :maps_to,
                  :template_script_id, :template_script_type, :aasm_state, :file_path

  # stored in `tag_id` column in `scripts` table
  Tag = [['Template', 1], ['System', 2], ['User', 3]]

  # initialize AASM state machine for object status
  init_state_machine

  def can_be_archived?
    self.in_use_by == 0
  end
  
  class << self

    def tagged_as_template(automation_category = 'all', automation_type = nil)
      automation_type = automation_type.nil? ? "Automation" : automation_type
      if List.get_list_items("AutomationCategory").include?(automation_category)
        Script.where('automation_category = ? AND tag_id = 1 AND automation_type = ?', automation_category, automation_type)
      else
        [Script.where(:tag_id => 1)].flatten
      end
      # case automation_category
      # when "General", "Hudson/Jenkins", "BMC Remedy 7.6.x", "BMC Application Automation 8.2"
      #   Script.where('automation_category = ? AND tag_id = 1 AND automation_type = ?', automation_category, automation_type)
      # when "all"
      #   [Script.where(:tag_id => 1)].flatten
      # else
      #   [Script.where(:tag_id => 1)].flatten
      # end
    end

    def automation_popup
      automation_types = List.get_list_items("AutomationCategory")
      if automation_types.present?
        automation_types << ["BMC Bladelogic"]
      end
      # automation_types = {"BMC Bladelogic" => "bladelogic_enabled", "SSH - Capistrano" => "capistrano_enabled", "Hudson/Jenkins" => "hudson_enabled"}
      popup = [["Manual","manual"]]
      automation_types.flatten.each do |type|
        if type == "BMC Bladelogic"
          popup << [type, "BladelogicScript"] if GlobalSettings[:bladelogic_enabled] == true
        else
          popup << [type, type.to_s] if GlobalSettings.automation_available?
        end
      end
      popup
    end

    def build_script_list
      res_class = script_class(params["script_class"])
      if res.nil?
        res = ["Select Automation Type"]
      else
        res = res_class.sorted
      end
      res
    end

    def script_class(script_txt) # Redundant. This was earlier used in ControllerSharedScript#build_script_list
      if script_txt.downcase.include?("bladelogic")
        res = BladelogicScript
      elsif List.get_list_items("AutomationCategory").map(&:downcase).include?(script_txt.downcase)
        res = Script
      else
        res = Script
      end
      res
    end

    def find_script(script_name)
        script_found = BladelogicScript.find_by_name(script_name)
        return script_found unless script_found.nil?
        script_found = Script.find_by_name(script_name)
        return script_found unless script_found.nil?
    end

    # Build List of script from federated ss server
    def import_script_list(integration_id)
      integration = ProjectServer.find(integration_id)
      server_info = integration.streamstep_integration_info
      ss_url = "#{server_info[:server_url]}/REST"
      sPath = "scripts/get_template_scripts?token=#{server_info[:token]}"
      puts "Fetching Request"
      results = fetch_results(sPath, ss_url)
      logger.info "Raw Results:\n#{results.inspect}"
      # hpricot was removed and the compatible decorator for nokogiri used
      doc = Nokogiri::Hpricot::XML(results)
      result = []
      (doc/:record).each do |script|
        script_type = script.at("script-type").innerHTML
        script_type = "CapistranoScript" if script_type == ""
        res = {
          "script_id" => script.at(:id).innerHTML,
          "script_name" => script.at(:name).innerHTML,
          "script_desc" => script.at(:description).innerHTML,
          "script_type" => script_type }
        result << res
      end
      result << "No Scripts found" if result.empty?
      result.sort_by { |my_item| my_item["script_name"] }
    end

    def fetch_results(path, base_url = "none")
      base_url = @ss_url if base_url == "none"
      tmp = "#{base_url}/#{path}".gsub(" ", "%20") #.gsub("&", "&amp;")
      jobUri = URI.parse(tmp)
      puts "Fetching: #{jobUri}"
      request = Net::HTTP.get(jobUri)
    end

    def get_attr_value(attr_name)
      found = @xml.at(attr_name.gsub("_","-"))
      val = found.nil? ? nil : (found.innerHTML == "" ? nil : found.innerHTML)
    end

    def filter_automation_script(filters)
      where(filters)
    end

  end

  def run_automation_script(params)
    # case script_type
    #   when "hudson"
    #     # do hudson specific stuff here
    # end
    run_script(params)
  end

  def test_run!(form_params = {})
    params = Hash.new
    args = form_params[:argument] || {}
    params["SS_script_type"] = "test"
    params["SS_script_target"] = get_script_type
    #params["SS_script_file"] = file_path
    if(form_params["app_id"] && form_params["app_id"].length > 0)
      params.merge!(AutomationCommon.test_script_values(form_params))
    end
    params["direct_execute"] = "yes" if direct_execute?
    args.each do |arg_id, value|
      arg = ScriptArgument.find(arg_id)
      argument_value = value.is_a?(Array) ? value.flatten.first : value
      params[arg.argument] = arg.is_private ? AutomationCommon.private_flag(argument_value) : argument_value
    end
    params.merge!(AutomationCommon.build_params(params))
    params.merge!(AutomationCommon.build_server_params(form_params["installed_component_id"]))
    params = AutomationCommon.encrypt_values(params)
    AutomationCommon.init_run_files(params, content)
    @script_result = run_script(params)
    @script_result += "\nERROR STATUS: " + (AutomationCommon.error_in?(@script_result) ? "Problem" : "Success") + "\n"
  end

  def run!(step)
    return unless step
    params = Hash.new
    params["SS_script_type"] = "step"
    params["SS_script_target"] = get_script_type
    params["SS_script_file"] = file_path
    params["direct_execute"] = "yes" if direct_execute?
    params.merge!(AutomationCommon.build_params(params, step))
    params.merge!(AutomationCommon.build_server_params(step))
    params = AutomationCommon.encrypt_values(params)
    AutomationCommon.init_run_files(params, content)
  
    # Run the script
    @script_result = run_script(params)
    @script_result += "\nSCRIPT STATUS: " + (AutomationCommon.error_in?(@script_result) ? "Problem" : "Success") + "\n"
    step.notes.create(:content => "\nScript Results:\n#{@script_result.split("\n").last(20).join("\n")}\n\n", :user_id => step.request.user_id)
  
    if AutomationCommon.error_in?(@script_result)
      step.problem!
    else
      step.set_property_values_from_script(@script_result)
      step.all_done!
    end
  end
  
  def file_path
    "#{default_path}/#{id}.script" if persisted?
  end
  
  def run_script(params, from_sync = false)
    #now send params hash - script_name, script_type, input_file = 'none'
    if self.automation_category == "General"
      run_general_script(params)
    elsif self.automation_category == "Bladelogic"
      run_bladelogic_script(params)
    else
      argument_string = "_SS_INPUTFILE='#{params["SS_input_file"]}'"
      if params["direct_execute"].nil?
        command = "#{RUBY_PATH} cap -f '#{params["SS_script_file"]}'" #" execute"
      else
        command = "#{RUBY_PATH} '#{params["SS_script_file"]}'"
      end
      @delay_log.puts "Executing script: #{command}" if @delay_log
      msg = "#{params["SS_script_target"].humanize} - Running command: \n#{command}"
      AutomationCommon.append_output_file(params, msg)
      AutomationCommon.append_output_file(params,AutomationCommon.output_separator("RESULTS"))
      logger.info "=== Automation Command: #{command}"
      script_result = ""
      err = ""
      status = IO::popen4(command) do |pid, stdin, stdout, stderr|
        stdin.close
        [
          Thread.new(stdout) {|stdout_io|
            stdout_io.each_line do |l|
              script_result += l
            end
            stdout_io.close
          },

          Thread.new(stderr) {|stderr_io|
            stderr_io.each_line do |l|
              err += l
            end
          }
        ].each( &:join )
        params["SS_process_pid"] = pid
      end
      script_result += exit_code_failure(params)
      AutomationCommon.append_output_file(params, "\nProcess ID: #{params["SS_process_pid"]}\n")
      err = "\n[STATUS: " + err + "]" if err.length > 4
      script_result += err
      AutomationCommon.append_output_file(params, "\nSTDERR: #{err}\n") if err.length > 4
      output = "\n[Script output written to: #{params["SS_output_file"]}]\n"
      script_result += output
      logger.info "#{params["SS_script_target"].humanize} - Automation finished\n#{output}"
      if params.has_key?("SS_job_run_id") # Running in background
        jr = JobRun.find(params["SS_job_run_id"])
        jr.stdout = script_result
        jr.stderr = err
      end
      script_result

    end
  end

  def run_eval(eval_string)
    error_flag = "#!!!__Error_in_Script__!!!#\n"
    result = {"status" => "Success"}
    output = "#--------------- Resource Automation Results -----------------#\n"
    begin
      result["result"] = eval(eval_string)
      output += result["result"].to_s
    rescue Exception => err
      output += error_flag
      output += err.message + "\n" + err.backtrace.join("\n")
      result["status"] = "Error"
      result["error"] = output
    end
    result["output"] = output
    result
  end
  
  def run_resource_automation(step, argument_hash, parent_id = "nil", offset = 0, per_page = 0)
    # load up the params to be appended with form variables
    params_to_be_appended = {}
    argument_hash.each do |key, value|
      params_to_be_appended[key] = value
    end      
  
    # get the expected Step params for automation by using the passed step
    params = queue_run!(step, "false", params_to_be_appended)
    # pull the file back in from the file system
    automation_script_header = File.open("#{params["SS_script_file"]}").read        
    # eval the script in memo
    # CHKME: protection against out of memory, time outs, and unauthorized object access.
    if parent_id.blank?
      parent_id = "nil"
    else
      parent_id = "\"#{parent_id}\""
    end
    logger.info "SS__ Run Resource Auto: args: #{AutomationCommon.hash_to_sorted_yaml(params_to_be_appended)}"
    script_result = run_eval("#{automation_script_header};execute(params, #{parent_id}, #{offset}, #{per_page});")
    if script_result["status"] == "Error"
      AutomationCommon.append_output_file(params, "\n#{script_result["error"] + script_result["output"]}\n")
    else
      job = JobRun.find_by_id(params["SS_job_run_id"])
      job.complete_job
    end
    script_result
  end

  def set_automation_category_type
    self.automation_type = "ResourceAutomation" if automation_type.blank?
  end

  def update_position_arguments
    position_array = self.arguments.map(&:position)
    if position_array.include?(nil)
      update_default_position_for_arguments(self.arguments.input_arguments.sort)
      update_default_position_for_arguments(self.arguments.output_arguments.sort)
    end
  end

  def script_external_resource
    arguments.map{ |a| a.external_resource }.compact
  end

  def update_owner
    if created_by.nil?
      self.created_by = User.current_user.try(:id)
    end
  end
  
  private

    def parse_arguments_with_filter_comments
      result = parse_arguments_without_filter_comments
      result.gsub!(/^\s*#/m, '') if result
      result
    end

    alias_method_chain :parse_arguments, :filter_comments

    def argument_regex
      ARGUMENT_REGEX
    end

  def update_default_position_for_arguments(argument_types)
    argument_types.each_with_index do |argument, index|
      index1 = index + 1
      argument.update_attribute(:position, "A#{index1}:B#{index1}")
    end
  end

  def exit_code_failure(params = {})
    (params['ignore_exit_codes'] == 'yes' || $?.exitstatus == 0) ? '' : "\n#{SharedScript::EXIT_CODE_FAILURE}\n"
  end

end
