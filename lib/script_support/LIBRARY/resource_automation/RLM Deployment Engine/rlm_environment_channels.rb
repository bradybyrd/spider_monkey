###
# Route:
#   name: Route
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: rlm_routes
#   required: yes
# Environment:
#   name: Environment
#   type: in-external-single-select
#   external_resource: rlm_route_environments
#   position: E5:F5
#   required: yes
###

require 'yaml'
require 'script_support/rlm_utilities'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  RlmUtilities.get_environment_channels(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, script_params['Environment'])
end

def import_script_parameters
  {'render_as' => 'Table'}
end
