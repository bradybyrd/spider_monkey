################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'fileutils'
require 'open3'

class BladelogicScript < ActiveRecord::Base
  include SharedScript

  paginate_alphabetically :by => :name

  OLD_ARGUMENT_REGEX = /\s*"""\r?\n(.+?)(\r?\n)+?\s*"""/m
  # Converting blade logic to ruby style argument blocks to avoid triple quote parameter bug
  ARGUMENT_REGEX = /\s*^###\r?\n(.+?)(\r?\n)+?\s*^###\r?/m

  #BJB Move to central location 6/21/10
  DEFAULT_BLADELOGIC_SUPPORT_PATH = AutomationCommon::DEFAULT_AUTOMATION_SUPPORT_PATH
  DEFAULT_BLADELOGIC_SCRIPTS_PATH = "#{Rails.root}/public/bladelogic_scripts"
  DEFAULT_BLADELOGIC_SCRIPT_HEADER_PATH = "#{DEFAULT_BLADELOGIC_SUPPORT_PATH}/bladelogic_script_header.py"
  DEFAULT_BLADELOGIC_ENV_HEADER_PATH = "#{DEFAULT_BLADELOGIC_SUPPORT_PATH}/bladelogic_env.py"
  # automation results has been moved to comfiguration file and is loaded above automation_settings.rb
  #OUTPUT_BASE_PATH = "#{Rails.root}/public/automation_results"


  has_many :arguments, :class_name => 'BladelogicScriptArgument', :foreign_key => 'script_id', :dependent => :destroy
  has_many :steps, :foreign_key => 'script_id'
  serialize :choices, Array

  validates :name,
            :presence => true,
            :uniqueness => true
  validates :content,
            :presence => true
  validates :authentication,
            :presence => true
  validates :authentication,
            :inclusion => {:in => ['step', 'default']}

  validate :bladelogic_argument_syntax_validation

  before_save :check_content, :set_script_type
  after_save :update_arguments

  attr_accessor :template_script

  before_destroy :fails_if_in_use, :clear_scripts_when_not_in_use
  after_destroy :delete_content

  scope :sorted, order('name')
  scope :filter_by_name, ->(name) { where 'LOWER(bladelogic_scripts.name) like ?', "%#{name.downcase}%" }

  attr_accessible :name, :description, :content, :authentication, :tag_id, :script_type

  def step_authentication?
    authentication == 'step'
  end

  def default_authentication?
    authentication == 'default'
  end

  def test_run!(form_params) #(args = {})
    params = Hash.new
    args = form_params[:argument] || {}
    params["SS_script_type"] = "test"
    params["SS_script_target"] = get_script_type
    if(form_params["app_id"] && form_params["app_id"].length > 0)
      params.merge!(AutomationCommon.test_script_values(form_params))
    end
    args.each do |arg_id, value|
      arg = BladelogicScriptArgument.find(arg_id)
      params[arg.argument] = arg.is_private ? AutomationCommon.private_flag(value) : value
    end
    params.merge!(AutomationCommon.build_params(params))
    params.merge!(AutomationCommon.build_server_params(form_params["installed_component_id"]))
    params = AutomationCommon.encrypt_values(params)

    # Create the run files for the automation
    AutomationCommon.init_run_files(params, content)
    # Execute the script
    return run_bladelogic_script(params)
  end

  # BJB 6/21/10 Adding common routines for Bladelogic support
  # Get the bladelogic login parameters from GlobalSettings
  def run!(step)
    return unless step
    params = Hash.new
    params["SS_script_type"] = "step"
    params["SS_script_target"] = get_script_type
    params["SS_script_file"] = file_path
    if self.authentication == 'step' && step.owner.bladelogic_user
      #  ---- NOTE: Now we need a profile, not username #
      params["SS_auth_type"] = 'step'
      params["bladelogic_profile"] = step.owner.bladelogic_user.username
      params["bladelogic_role"] = step.bladelogic_role
    end
    params.merge!(AutomationCommon.build_params(params, step))
    params.merge!(AutomationCommon.build_server_params(step))
    params = AutomationCommon.encrypt_values(params)

    # Create the input file for the arguments
    AutomationCommon.init_input_file(params)
    AutomationCommon.init_output_file(params, content)
    # Execute the script
    @script_result = run_bladelogic_script(params)

    step.notes.create(:content => "\nScript Results:\n#{@script_result}\n\n", :user_id => step.request.user_id)

    if AutomationCommon.error_in?(@script_result)
    step.problem!
    else
    step.set_property_values_from_script(@script_result)
    step.all_done!
    end
  end

  def file_path
    "#{default_path}/#{id}.script"
  end

  def bl_authenticate(params)
    # 1. Prepare output_file.txt
    output_file = FileInUTF.open(params["SS_output_file"], "a")
    output_file.puts(AutomationCommon.output_separator("BLADELOGIC AUTHENTICATION"))
    # 2. Call the bl_login script with Open3.popen3 to set the credential token
    login_cmd_tmpl = "#{RUBY_PATH} \"#{DEFAULT_BLADELOGIC_SUPPORT_PATH}/bl_login\" "
    login_cmd = login_cmd_tmpl + "#{auth_header(params)}"
    logger.info "=== Automation Command: #{login_cmd_tmpl}#{auth_header(params, true)}"
    script_result = ""
    err = ""
    status = IO::popen4(login_cmd) do | pid, stdin, stdout, stderr|
      script_result = stdout.read.to_s
      err = stderr.read.to_s
      params["SS_process_pid"] = pid
    end
    AutomationCommon.append_output_file(params, "\nProcess ID: #{params["SS_process_pid"]}\n")
    if err.length < 2
      output_file.print "#{Time.now.to_s}: Successfully Acquired Credential for #{GlobalSettings[:bladelogic_profile]}\n"
    else
      output_file.print("\n\nError enountered while executing #{login_cmd}\n")
      output_file.print("\nERROR: #{err}\n")
    end
    output_file.close
    err.length < 2
  end

  def script_file(file_name)
    contents = File.open(file_name).read
  end

  def project_server
    nil
  end

  def run_bladelogic_script(params, from_sync = false)
    #now send params hash - script_name, script_type, input_file = 'none'
    outdir = params["SS_output_dir"]
    input_file = params["SS_input_file"]
    result = ''
    if bl_authenticate(params)
      command_prefix = Windows ? "cmd /c " : ""
      command = "#{command_prefix}bljython \"#{params["SS_script_file"]}\" \"#{input_file == 'none' ? '': input_file}\""
      logger.info "=== Automation Command: #{command}"
      script_result = ""
      err = ""
      status = IO::popen4(command) do | pid, stdin, stdout, stderr |
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
      AutomationCommon.append_output_file(params, "\nProcess ID: #{params["SS_process_pid"]}\n")
      output_file = FileInUTF.open(params["SS_output_file"], "a")
      output_file.print(AutomationCommon.output_separator("Execute Command"))
      output_file.print("\nRunning: #{command}\n")
      output_file.print(AutomationCommon.output_separator("RESULTS"))
      result += "STDOUT: \n#{script_result}\n"
      if err.length < 4
        logger.info "[BladeLogic] - Command returned [#{script_result}]"
        output_file.print("\n#{script_result}\n\n")
      else
        output_file.print("\n[STDERR: #{err}]\n\n")
        output_file.print("\n#{script_result}\n\n")
        result += "[STDERR: #{err}]\n#{script_result}\n"
      end
      #ActiveRecord::Base.establish_connection Rails.env.to_sym
    end
    result += "\n[Script output written to: #{params["SS_output_file"]}]\n"
    output_file.close if output_file
    result
  end

  def update_bladelogic_arguments
    # Fixes old blade argument structure
    old_delimiter = "\"\"\""
    if self.content.include?(old_delimiter)
      arg_string = self.content.match(OLD_ARGUMENT_REGEX)
      result = arg_string[1] if arg_string
      result.gsub!("\n","\n# ")
      result = "# " + result
      self.content = content.gsub(old_delimiter,"###").gsub(arg_string[1],result)
      self.save(:validate => false)
    end
  end

  private

  def auth_header(params, hide_password = false)
    authenticate_header = " _BL_IP='#{GlobalSettings[:bladelogic_ip_address]}'"     +
                          " _BL_USERNAME='#{GlobalSettings[:bladelogic_username]}'" +
                          " _BL_PASSWORD="

    authenticate_header += hide_password ? "'******'" : "'#{GlobalSettings[:bladelogic_password]}'"

    authenticate_header +=
      if params["auth_type"].nil? || params["auth_type"] == "default"
        " _BL_ROLE='#{GlobalSettings[:bladelogic_rolename]}'" +
        " _BL_PROFILE='#{GlobalSettings[:bladelogic_profile]}'"
      else
        " _BL_ROLE='#{params["bladelogic_role"]}'" +
        " _BL_PROFILE='#{params["bladelogic_profile"]}'"
      end
  end

  def package_template_properties_file_path(step)
    File.makedirs(ComponentTemplate::OUTPUT_BASE_PATH) unless File.file?(ComponentTemplate::OUTPUT_BASE_PATH)
    properties_file = File.new("#{ComponentTemplate::OUTPUT_BASE_PATH}/#{step.id}_package_template_properties.txt", "w+")
    package_template_items = PackageTemplateItem.component_instances(step[:package_template_properties].keys)
    component_instances = package_template_items.map(&:id)
    components, commands = '', ''
    step[:package_template_properties].each_pair { |template_item_id, properties|
      if component_instances.include?(template_item_id.to_i)
        properties.each_pair { |property_name, property_value |
          components += " #{property_name}=#{property_value} "
        }
      else
        commands += " COMMAND=#{properties['command']} UNDO_COMMAND=#{properties['undo_command']}"
      end
    }
    properties_file.write("#{components}\n")
    properties_file.write(commands)
    properties_file.close
    "_SS_PACKAGE_TEMPLATE_PROPERTIES_FILE='#{properties_file.path}'"
  end

  def headers_for_step(step)
    "_SS_PROCESS=#{step.business_process_name}\n"   +
    "_SS_RELEASE=#{step.release_name}\n"            +
    "_SS_APPLICATION=#{step.app_name}\n"            +
    "_SS_ENVIRONMENT=#{step.environment_name}\n"    +
    "_SS_REQUEST=#{step.request_number}\n"          +
    "_SS_STEP_ID=#{step.id}\n"                      +
    "_SS_STEP_NUMBER=#{step.number}\n"              +
    "_SS_STEP_NAME=#{step.name}\n"                  +
    "_SS_STEP_OWNER=#{step.owner_name}\n"           +
    "_SS_STEP_COMPONENT=#{step.component_name}\n"   +
    "_SS_STEP_STARTED_AT=#{step.work_started_at}\n" +
    "_SS_SERVERS=#{step.server_association_names.join(',')}\n "
  end

  def default_path
    DEFAULT_BLADELOGIC_SCRIPTS_PATH
  end

  def parse_arguments_with_filter_comments
    result = parse_arguments_without_filter_comments
    result.gsub!(/^\s*#/m, '') if result

    result
  end

  alias_method_chain :parse_arguments, :filter_comments

  def argument_regex
    ARGUMENT_REGEX
  end

  def error_in?(result)
    #(result =~ /^\s*\[err ::[^\]]*\]/).nil?
    !(result =~ /\[ERROR: /).nil?
  end

  def bladelogic_argument_syntax_validation
    check_content
    if @content_changed
      args_from_content = in_order_arguments

      # If we get 'false' as any element in the arguments, then parsing has failed
      if args_from_content.include?(false)
        self.errors[:base] << "Argument parsing error"
      end
    end
  end

  def set_script_type
    self.script_type = self.class.name
  end

end
