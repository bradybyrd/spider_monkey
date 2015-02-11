# Jira: Get Issue Status
# Get the status of an issue
###
# login_name:
#   name: Jira login name
# login_password:
#   name: Jira login pasword
# jira_address:
#   name: Jira server address (e.g. http:\\jira.atlassian.com)
# issue_key:
#   name: Jira issue name for which status will be returned
###

# Flag the script for direct execution
params["direct_execute"] = true

#==============  User Portion of Script ==================

# Jira support is provided by the Jira4R gem installed by default
require 'rubygems'
require 'jira4r'



gem 'soap4r'
require 'soap/mapping'

login_name = params['login_name']
login_password = params['login_password']
jira_address = params['jira_address']
issue_key = params['issue_key']

# make a connection to the Jira instance
j = Jira4R::JiraTool.new(2,jira_address)

# login to Jira
j.login(login_name,login_password)

unless issue_key.nil?
  # get the issue
  issue_or_error = j.getIssue(issue_key)
  # make sure it is not nil or an error string
  unless issue_or_error.nil? || issue_or_error.is_a?(String)
    # get the status id
    status_id = issue_or_error.status
    unless status_id.nil?
      # find the human name for the status
      status_types_or_error = j.getStatuses()
      
      unless status_types_or_error.nil? || status_types_or_error.is_a?(String)
        
        # find the matching status type
        status = status_types_or_error.select{ |s| s.id == status_id}.first
        
        # store the status in the result field
        result = "issue:#{issue_or_error.key} status: #{status.name}"
      else
        result = status_types_or_error
      end
    else
      result = "No status type for issue."  
    end
  else
    result = issue_or_error
  end
end
write_to result

# Apply success or failure criteria
success = "issue:#{issue_key} status: "
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end

