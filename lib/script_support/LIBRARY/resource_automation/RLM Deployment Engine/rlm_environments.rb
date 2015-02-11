require 'yaml'
require 'script_support/rlm_utilities'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  rlm_environments = RlmUtilities.get_all_environments(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD)
  select_hash = {}
  select_hash["Select"] = ""
  rlm_environments.unshift(select_hash)
  return rlm_environments
end

def import_script_parameters
  { "render_as" => "List" }
end