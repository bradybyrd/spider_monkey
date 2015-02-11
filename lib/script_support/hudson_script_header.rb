################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'rubygems'
require 'rexml/document'
require 'net/http'
require 'uri'
require 'hudson-remote-api'
require 'json'


def set_hudson_config(config_token)
  #Config token is array ["http://ec2-50-16-13-51.compute-1.amazonaws.com:8083", "streamstep", "desiderata"]
  @hudson_user = config_token[1]
  @hudson_password = config_token[2]
  @hudson_url = config_token[0]
  s = {}
  s["url"]= @hudson_url.chomp("/")
  s["user"]= @hudson_user
  s["password"]= @hudson_password
  Hudson.settings=(s)
end

def get_hudson_jobs
  jobs = Hudson::Job.list()
end

def get_hudson_job_parameters(cur_job)
  url = URI.escape("#{@hudson_url}/job/#{cur_job}/api/json")
  jobUri = URI.parse(url)
  jj = JSON.parse( Net::HTTP.get(jobUri) )
  params = jj["actions"][0]["parameterDefinitions"]
end

def get_url(path, testing=false)
  cur_path = path.slice(0..3) == 'http' ? path : "#{@hudson_url}/#{path[0..0] == "/" ? path[1..1024] : path}"
  tmp = URI.escape(cur_path)  #.gsub(" ", "%20") #.gsub("&", "&amp;")
  jobUri = URI.parse(tmp)
  puts "Fetching: #{jobUri}"
  request = Net::HTTP.get(jobUri) unless testing
end

# return the console output of the last build
def last_build_output(jobname, build_no = nil)
  url = "#{@hudson_url}/job/#{jobname}/#{build_no.nil? ? "lastBuild" : build_no}/consoleText"
  xmlBuild = get_url(url)
end

def last_build_artifacts(jobname, build_no = nil)
  url = "#{@hudson_url}/job/#{jobname}/#{build_no.nil? ? "lastBuild" : build_no}/api/xml"
  xmlBuild = get_url(url)
  build_doc=REXML::Document.new(xmlBuild)
   build_url_root=build_doc.elements["/*/url"].text()
   artifacts=[]

   build_doc.elements.each("/*/artifact/"){ |e|
      artifacts << build_url_root + "artifact/" + e.get_elements("relativePath")[0].text
   }
   artifacts
end

