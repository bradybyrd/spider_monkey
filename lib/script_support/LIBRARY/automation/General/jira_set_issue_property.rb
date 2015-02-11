# Jira: Set Property of an Issue
# Sets an arbitrary property of an issue; see http://docs.atlassian.com/software/jira/docs/api/rpc-jira-plugin/latest/index.html?com/atlassian/jira/rpc/soap/JiraSoapService.html
###
# login_name:
#   name: Jira login name
# login_password:
#   name: Jira login pasword
# jira_address:
#   name: Jira server address (e.g. http:\\jira.atlassian.com)
# issue_key:
#   name: Jira issue name for which status will be returned
# issue_field_name:
#   name: The field name of the updated field
# issue_field_value:
#   name: The value of the updated field
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
issue_field_name = params['issue_field_name']
issue_field_value = params['issue_field_value']

# make a connection to the Jira instance
j = Jira4R::JiraTool.new(2,jira_address)

# login to Jira
j.login(login_name,login_password)

unless issue_field_name.nil? || issue_field_value.nil?

  # set the issue status

  remote_field_value =  Jira4R::V2::RemoteFieldValue.new(issue_field_name, issue_field_value)

  # update the remote issue
  issue_or_error = j.updateIssue(issue_key, remote_field_value)

  # make sure it is not nil or an error string
  unless issue_or_error.nil? || issue_or_error.is_a?(String)
    # store the status in the result field
    result = "Updated issue #{issue_or_error.key}'s #{issue_field_name} with: #{issue_field_value}"
  else
    # stuff the error in the results
    result = issue_or_error
  end
end
write_to result

# Apply success or failure criteria
success = "Updated issue"
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end

