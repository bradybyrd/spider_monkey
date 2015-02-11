# Jira: Sends a progress workflow message by work flow transition id
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
# workflow_transition_id:
#   name: The workflow transition id for the action
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
workflow_transition_id = params['workflow_transition_id']

# make a connection to the Jira instance
j = Jira4R::JiraTool.new(2,jira_address)

# login to Jira
j.login(login_name,login_password)

unless issue_key.nil? || workflow_transition_id.nil?

  # send the workflow step id to the issue
  issue_or_error = j.progressWorkflowAction(issue_key,workflow_transition_id,nil)

  # make sure it is not nil or an error string
  unless issue_or_error.nil? || issue_or_error.is_a?(String)
    # store the status in the result field
    result = "Updated workflow for issue #{issue_or_error.key} with workflow transition id #{workflow_transition_id}; Issue now has status #{issue_or_error.status}."
  else
    # stuff the error in the results
    result = issue_or_error
  end
end
write_to result

# Apply success or failure criteria
success = "Updated workflow"
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end

