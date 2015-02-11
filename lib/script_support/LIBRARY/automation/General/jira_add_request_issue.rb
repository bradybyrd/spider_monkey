# Jira: Add Request as Task of Project
# Adds the current request as a new task for the Project
###
# comment_body:
#   name: Comment body text to submit to Jira
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
login_name = SS_integration_username #params['login_name']
login_password = decrypt_string_with_prefix(SS_integration_password_enc) #params['login_password']
jira_address = SS_integration_dns #params['jira_address']
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

    # create an issue
    issue =  Jira4R::V2::RemoteIssue.new()

    if params.has_key?('SS_request_number')
      # assemble the request name
      request_name = "#{params['request_name']} (#{params['SS_request_number']})"
      description =<<-END
Request Details:
Started At: #{params["request_started_at"]}
Requestor: #{params["requestor"]}
Application: #{params["SS_application"]}
Environment: #{params["SS_environment"]}
Started At: #{params["request_started_at"]}
Description:
#{params["request_description"]}
END


    else
      # if there is no request, use the test name
      request_name = 'Test BMC RLM'
      description = comment_body
    end

    # populate the fields
    issue.project = project_key
    #issue.assignee = "iceman" #login_name
    issue.description = description
    issue.summary = request_name
    issue.type = issue_type_id
    issue.duedate = Time.now
    save_result = j.createIssue(issue)
    unless save_result.is_a?(String) && save_result.index('Error').nil?
      result = "Added issue for #{issue.summary}. "
      # cache the newly saved issue
      saved_issue = save_result
    else
      result = save_result
    end

    unless saved_issue.nil? || saved_issue.key.nil?

      # initialize a comment
      comment = Jira4R::V2::RemoteComment.new()

      # populate the comment fields
      comment.author = login_name
      comment.body = comment_body

      #add the comment to the issue
      j.addComment(saved_issue.key, comment)
      result += "#---------  Adding Jira Issue ---------------#\n"
      result += "Added comment '#{comment.body}' to issue: #{saved_issue.key}."
    end
  end
end

write_to result ||= 'Invalid parameters sent to script.'

# Apply success or failure criteria
success = request_name
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end
