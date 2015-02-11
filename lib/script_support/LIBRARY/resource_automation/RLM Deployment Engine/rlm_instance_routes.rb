###
# Package:
#   name: RLM Package
#   position: A1:B1
#   type: in-external-single-select
#   external_resource: rlm_packages
#   required: yes
# Instance:
#   name: Choose Package instance
#   type: in-external-single-select
#   external_resource: rlm_package_instances
#   position: E1:F1
#   required: yes
###



require 'yaml'
require 'script_support/rlm_utilities'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  rlm_routes = RlmUtilities.get_all_instance_routes(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, script_params['Instance'])
  rlm_routes = RlmUtilities.get_all_routes(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD) if rlm_routes.blank?
  select_hash = {}
  select_hash["Select"] = ""
  rlm_routes.unshift(select_hash)
  return rlm_routes
end

def import_script_parameters
  { "render_as" => "List" }
end