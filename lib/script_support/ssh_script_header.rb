################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# ----------- Includes ---------------------#
require 'rubygems'
require 'net/http'
require 'uri'
require 'yaml'
require 'fileutils'
require 'cgi'
require 'json'

EXIT_CODE_FAILURE = 'Exit_Code_Failure'

def load_helper(lib_path)
  require "#{lib_path}/script_helper.rb"
  require "#{lib_path}/file_in_utf.rb"
end

# BJB 7/6/2010 Append a user script to the bottom of this one for cap execution
def load_input_params(in_file)
  params = YAML::load(File.open(in_file))
  load_helper(params["SS_script_support_path"])
  @params = strip_private_flag(params)
  @params
end

def get_param(key_name)
  @params.has_key?(key_name) ? @params["key_name"] : ""
end

def output_separator(phrase)
  divider = "==========================================================="
  "\n#{divider.slice(0..20)} #{phrase} #{divider.slice(0..(divider.length-phrase.length))}\n"
end

def write_to(message, newline = true)
  return if message.nil?
  sep = newline ? "\n" : ""
  @hand.print(message + sep)
  print(message + sep)
end

def create_output_file(params)
  @output_file = params["SS_output_file"]
  @hand = FileInUTF.open(@output_file, "a")
  write_to "New Run - Shell Cmd: #{params["command"]}\n\n"
  return true
end

def run_command(params, command, arguments, b_quiet = false)
  command = command.is_a?(Array) ? command.flatten.first : command
  data_returned = ""
  write_to("========================\n Running: #{command} \n========================") unless b_quiet
  if params["direct_execute"].nil?
    use_sudo = params["sudo"].nil? ? "no" : params["sudo"]
    set :user, params["user"] unless params["user"].nil?
    set :password, params["password"] unless params["password"].nil?

    # Create the command
    first_time = true
    rescue_cap_errors(params) do
      command = "#{use_sudo == 'yes' ? sudo : '' } #{command} #{arguments}"
      command += exit_code_failure(params)
      run command, :pty => (use_sudo == 'yes') do |ch, str, data|
        # santize data returned so it can't affect the html
        data = CGI::escapeHTML(data)
        if str == :out
          if first_time
          msg = "STDOUT: #{data}"
          write_to msg  unless b_quiet
          data_returned += msg
          first_time = false
          else
            msg = data
            if data_returned.length > 30000
            data_returned.slice!(data.length..data_returned.length)
            data_returned += output_separator("Data Truncated")
            end
          data_returned += msg
          write_to(msg, false)  unless b_quiet
          end
        elsif str == :err 
          msg = "STDERR: #{data}\n"
          write_to(msg, false) if data.length > 4 && params['ignore_exit_codes'] == 'no'
          data_returned += msg if data.length > 4
        end
      end
    end
  else # Direct Execute the command
  data_returned = `#{command} #{arguments} 2>&1`
  data_returned = CGI::escapeHTML(data_returned)
  write_to data_returned  unless b_quiet
  end
  write_to("=============  Results End ==============")  unless b_quiet
  return data_returned
end

def get_server_list(params)
  rxp = /server\d+_/
  slist = {}
  lastcur = -1
  curname = ""
  params.sort.reject{ |k| k[0].scan(rxp).empty? }.each_with_index do |server, idx|
    cur = (server[0].scan(rxp)[0].gsub("server","").to_i * 0.001).round * 1000
    if cur == lastcur
    prop = server[0].gsub(rxp, "")
    slist[curname][prop] = server[1]
    else # new server
      lastcur = cur
      curname = server[1].chomp("0")
      slist[curname] = {}
    end
  end
  return slist
end

def get_servers_by_property_value(prop_name, value, servers = nil)
  servers = get_server_list(@params) if servers.nil?
  hosts = []
  servers.each_with_index do |server, idx|
    server[1].each do |prop, val|
      hosts << server if (prop.downcase == prop_name.downcase && val.downcase.include?(value.downcase))
    end
  end
  hosts
end

def get_selected_hosts(server_list = nil)
  serverlist = get_server_list(@params) if serverlist.nil?
  hosts = server_list.map{ |srv| srv[0] }
end

def get_integration_details(details_yml)
  # SS_integration_details = "Project: TST\nDefault item: lots of stuff\n"
  ans = {}
  lines = details_yml.split("\n")
  itemcnt = 1
  lines.each do |item|
    it = item.split(": ")
    ans[it[0]] = it[1] if it.size == 2
    ans["item_#{itemcnt.to_s}"] = it[0] unless it.size == 2
    itemcnt += 1
  end
  ans
end

def set_property_flag(prop, value = nil)
  acceptable_fields = ["name", "value", "environment", "component", "global", "private"]
  flag = "#------ Block to Set Property ---------------#\n"
  if value.nil?
    flag += set_build_flag_data("properties", prop, acceptable_fields)
  else
    flag += "$$SS_Set_property{#{prop}=>#{value}}$$"
  end
  flag += "\n#------- End Set Property ---------------#\n"
  write_to flag
  flag
end

def set_server_flag(servers)
  # servers = "server_name, env\ncserver2_name, env2"
  acceptable_fields = ["name", "environment", "group"]
  flag = "#------ Block to Set Servers ---------------#\n"
  flag += set_build_flag_data("servers", servers, acceptable_fields)
  flag += "\n#------ End Set Servers ---------------#\n"
  write_to flag
  flag
end

def set_component_flag(components)
  # comps = "comp_name, version\ncomp2_name, version2"
  flag = "#------ Block to Set Components ---------------#\n"
  acceptable_fields = ["name", "version", "environment", "application"]
  flag += set_build_flag_data("components", components, acceptable_fields)
  flag += "\n#------ End Set Components ---------------#\n"
  write_to flag
  flag
end

def set_titles_acceptable?(cur_titles, acceptable_titles)
  cur_titles.each.reject{ |cur| acceptable_titles.include?(cur)}.count == 0
end

def set_build_flag_data(set_item, set_data, acceptable_titles)
  flag = ""; msg = ""
  lines = set_data.split("\n")
  titles = lines[0].split(",").map{ |it| it.strip }
  if set_titles_acceptable?(titles, acceptable_titles)
    flag += "$$SS_Set_#{set_item}{\n"
    flag += "#{titles.join(", ")}\n"
    lines[1..-1].each do |line|
      if line.split(",").count == titles.count
        flag += "#{line}\n"
      else
        msg += "Skipped: #{line}"
      end
    end
    flag += "}$$\n"
  else
    flag += "ERROR - Unable to set #{set_item} - improper format\n"
  end
  flag += msg
end

def set_application_version(prop, value)
  # set_application_flag(app_name, version)
  flag = "#------ Block to Set Application Version ---------------#\n"
  flag += "$$SS_Set_application{#{prop}=>#{value}}$$"
  flag += "\n#------ End Set Application ---------------#\n"
  write_to(flag)
  flag
end

def pack_response(argument_name, response)
  flag = "#------ Block to Set Pack Response ---------------#\n"
  unless argument_name.nil?
    if response.is_a?(Hash)
      # Used for out-table output parameter
      flag += "$$SS_Pack_Response{#{argument_name}@@#{response.to_json}}$$"
    else
      flag += "$$SS_Pack_Response{#{argument_name}=>#{response}}$$"
    end
  end
  flag += "\n#------- End Set Pack Response Block ---------------#\n"
  write_to flag
  flag
end


def rescue_cap_errors(params, &block)
  begin
    yield
  rescue RuntimeError => failure
    if params['ignore_exit_codes'] == 'no'
      write_to "SSH-Capistrano_Error: #{failure.message}"
      write_to(EXIT_CODE_FAILURE) 
    end  
  end
end

def hostname_from_url(url)
  url_frag = url.split(":")
  url = url_frag.size > 1 ? url_frag[1] : url_frag[0]
  url.gsub("//","")
end


def fetch_url(path, testing=false)
  ss_url = @params["SS_base_url"] #  Leave this alone
  tmp = (path.include?("://") ? path : "#{ss_url}/#{path}").gsub(" ", "%20").gsub("&", "&amp;")
  jobUri = URI.parse(tmp)
  puts "Fetching: #{jobUri}"
  request = Net::HTTP.get(jobUri) unless testing
end

def exit_code_failure(params)
  size_ = EXIT_CODE_FAILURE.size
  exit_code_failure_first_part  = EXIT_CODE_FAILURE[0..3]
  exit_code_failure_second_part = EXIT_CODE_FAILURE[4..size_]
  params['ignore_exit_codes'] == 'yes' ?
    '' :
    "; if [ $? -ne 0 ]; then first_part=#{exit_code_failure_first_part}; echo \"${first_part}#{exit_code_failure_second_part}\"; fi;"
end

results = "Error in command"

# Load the input parameters file and parse as yaml.
# params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
# create_output_file(params) #sets the @hand file handle
