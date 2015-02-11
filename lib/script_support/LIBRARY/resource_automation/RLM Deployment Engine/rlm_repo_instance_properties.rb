###
# Repo:
#   name: RLM Repo
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: rlm_repos
#   required: yes
# Instance:
#   name: Choose Repo instance
#   type: in-external-single-select
#   external_resource: rlm_repo_instances
#   position: E1:F1
#   required: yes
###

require 'yaml'
require 'script_support/rlm_utilities'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  rlm_package_properties = RlmUtilities.get_repo_instance_properties( RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, script_params["Instance"])
  return rlm_package_properties
end

def import_script_parameters
  { "render_as" => "Table" }
end