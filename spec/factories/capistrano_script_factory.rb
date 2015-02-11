script_content = <<-'SCRIPT_CONTENT'
###
# command:
#   name: Name of command
# success:
#   name: Term or Phrase to indicate success
###

#=== SSH Integration Server: historicusinc.com ===#
# [integration_id=1]
SS_integration_dns = "http://www.historicusinc.org"
SS_integration_username = "cforcey"
SS_integration_password = "-private-"
SS_integration_details = "A test ssh capable server."
#=== End ===#
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])

# Flag the script for direct execution
params["direct_execute"] = true

# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

# Run the command directly on the localhost
result = run_command(params, params["command"], '')

# Apply success or failure criteria
if result.index(params["success"]).nil?
write_to "Command_Failed - term not found: [#{params["success"]}]\n"
else
write_to "Success - found term: #{params["success"]}\n"
end

#Close the file
@hand.close
SCRIPT_CONTENT

FactoryGirl.define do
  factory :capistrano_script do
    sequence(:name) { |n| "Provision - Check last commit #{n}" }
    content script_content
  end
end

