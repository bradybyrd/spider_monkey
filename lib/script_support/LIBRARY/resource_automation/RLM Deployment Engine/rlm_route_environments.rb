###
# Route:
#   name: Route
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: rlm_routes
#   required: no
###


require 'yaml'
require 'script_support/rlm_utilities'
require 'base64'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  if script_params["Route"]
    rlm_environments = RlmUtilities.get_route_environments( RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, script_params["Route"], script_params["SS_environment"])
  else
    rlm_environments = []
  end
  if rlm_environments.first.empty?
    return rlm_environments
  elsif rlm_environments.first.keys.include?("#{script_params["SS_environment"]}(inherited from request)")
    val = rlm_environments.first["#{script_params["SS_environment"]}(inherited from request)"]
    rlm_environments.unshift({"#{script_params["SS_environment"]}(inherited from request)"=>val})
    return rlm_environments
  else
    select_hash = {}
    select_hash["Select"] = ""
    rlm_environments.unshift(select_hash)
    return rlm_environments
  end

end

def import_script_parameters
  { "render_as" => "List" }
end