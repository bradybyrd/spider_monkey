################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Script < ActiveRecord::Base

  require 'rexml/document'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'hudson-remote-api'

  attr_accessor :job

  validates :integration_id, :presence => {:if => Proc.new { |a| a.automation_category == "Hudson" }}

  before_validation :set_template_script_attributes

  # attr_accessible :name, :description, :content, :integration_id, :template_script, :job, :tag_id, :script_type

  HUMANIZED_ATTRIBUTES = {
    :integration_id => "Hudson Server",
    :template_script_type => "Script"
  }

  class << self

    def human_attribute_name(attr, options={})
      HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    # configure manually
    def hudson_config(integration=nil)
      @url = integration.try(:server_url) || "http://ec2-50-16-13-51.compute-1.amazonaws.com"
      @url += ":" + integration.port.to_s unless integration.port.nil?
      user = integration.try(:username) || "streamstep"
      password = integration.try(:password) || "desiderata"
      logger.info "SS__ Connecting Hudson: " + user + "/" + password + "@" + @url
      s = {}
      s["url"] = @url
      s["user"] = user
      s["password"] = password
      Hudson.settings = (s)
    end

    def get_hudson_jobs(integration=nil)
      hudson_config(integration)
      jobs = Hudson::Job.list()
    end

    def get_hudson_job_parameters(cur_job, integration=nil)
      Script.hudson_config(integration)
      url = URI.escape("#{@url}/job/#{cur_job}/api/json")
      #url = "#{@url}/job/#{cur_job}/api/json"
      jobUri = URI.parse(url)
      puts "Getting: #{jobUri}"
      http = Net::HTTP.new(jobUri.host, jobUri.port)
      request = Net::HTTP::Get.new(jobUri.path)
      user = integration.try(:username) || "streamstep"
      password = integration.try(:password) || "desiderata"
      request.basic_auth(user, password)
      request["Content-Type"] = "application/json" #set this before setting form data
      response = http.request(request)
      params = if response.message.include?("OK")
        jj = JSON.parse( response.body )
        jj["actions"][0]["parameterDefinitions"]
      else
        {"Error" => "Bad request"}
      end
    end

    def hudson_parameters_to_arguments(cur_job, integration, content)
      job_params = Script.get_hudson_job_parameters(cur_job, integration)

      prefix = "SS_hudson_"
      new_args = "\n" #new_args = "###\n"
      if job_params
        job_params.each do |jp|
          new_args += "# #{prefix}arg_#{jp["name"]}:\n"
          new_args += "#   description: #{jp["description"].length < 2 ? jp["name"] : jp["description"] }\n"
          new_args += "#   choices: #{jp["choices"].map.join(",")}\n" if jp["type"] == "ChoiceParameterDefinition"
        end
        new_args += "###\n"
      end
      new_args += prefix + "job= '#{cur_job}'\n"
      # wipe out existing args
      #content.gsub!(content.split("###")[1], new_args)
      #content.gsub!(/###.*###/m, new_args)
      #content
      new_args
    end

  end

  def job_parameters_in_yaml(cur_job, integration)
    get_hudson_job_parameters(cur_job, integration).to_yaml
  end

  private

  def default_path
    DEFAULT_HUDSON_SCRIPTS_PATH
  end

  def set_template_script_attributes
    return if template_script.blank?
    write_attribute(:template_script_type, template_script.split("_").first)
    write_attribute(:template_script_id, template_script.split("_").last)
  end

end
