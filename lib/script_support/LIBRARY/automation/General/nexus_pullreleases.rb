###
# nexus_base_url:
#   name: URL to check
# release_target:
#   name: release to find
###
# Flag the script for direct execution
params["direct_execute"] = true

# ========= Put User Script Items here =========#

url = "#{params["url_check"]}/#{params["SS_application"]}/#{params["SS_component"]}"
cmd = "wget -qO- #{url}"
# Run the command directly on the localhost
result = run_command(params, cmd, '')
#now parse html table returned by nexus
write_to "Testing URL: #{params["url_check"]}"
# Apply success or failure criteria
ipos = result.index(params["success"])
if ipos.nil?
  write_to "Command_Failed - term not found: [#{params["success"]}]\n"
else
  write_to "Success - found term: #{params["success"]}\n"
  write_to "Test Result: #{result.slice(ipos..(ipos + 50))}"
end
