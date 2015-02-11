# Jira: Add Comment to Issue
# Adds a comment + current step desription to issue
###
# issue_key:
#   description: ID for jira e.g. TST-3022
# comment_body:
#   description: Comment body text to submit to Jira
###

#=== Jira Integration Server: JIRA test atlassian ===#
# [integration_id=1]
SS_integration_dns = "https://jira.atlassian.com:443"
SS_integration_username = "bbyrd@bmc.com"
SS_integration_password = "-private-"
SS_integration_details = "Project: TST
"
#=== End ===#

# Flag the script for direct execution
params["direct_execute"] = true

#==============  User Portion of Script ==================

# Jira support is provided by the Jira4R gem installed by default
require 'rubygems'
require 'jira4r'

gem 'soap4r'
require 'soap/mapping'

# issue_type_id:
#   name: Issue type id (e.g. 1:Bug, 2:New Feature, 3:Task, 4:Improvement, 5:Epic, 6:Story, 7:Technical Task)

server_details = get_integration_details(SS_integration_details)
login_name = SS_integration_username
login_password = decrypt_string_with_prefix(SS_integration_password_enc)
jira_address = SS_integration_dns
issue_key = params['issue_key']
project_key = server_details['Project']
comment_body = params['comment_body'] || 'Added by BMC RLM.'
issue_type_id = '3'

unless jira_address.nil?
  # make a connection to the Jira instance
  j = Jira4R::JiraTool.new(2,jira_address)

  unless login_name.nil? || login_password.nil?
    # login to Jira
    j.login(login_name,login_password)

    # assemble the request name
    if params.has_key?('SS_request_number')
      description =<<-END
Comment from Request #{params["SS_request_number"]}
Step: #{params["step_id"]} - #{params["step_name"]}
Description:
#{comment_body}
#{params["step_description"]}
END

    else
      # if there is no request, use the test name
      request_name = 'Test BMC RLM'
      description = comment_body
    end
  end

  # initialize a comment
  comment = Jira4R::V2::RemoteComment.new()

  # populate the comment fields
  comment.author = login_name
  comment.body = description
  save_result = j.addComment(issue_key,comment)
else
  write_to result ||= 'Invalid parameters in integration.'
end
# Apply success or failure criteria
success = "method addComment"
result = success
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end
