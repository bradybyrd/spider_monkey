###
# Package:
#   name: RLM Package
#   position: A1:F1
#   type: in-external-single-select
#   external_resource: rlm_packages
#   required: yes
###

require 'yaml'
require 'script_support/rlm_utilities'

RLM_USERNAME = SS_integration_username
RLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
RLM_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  package_id = script_params["Package"].split("*")[0]
  array_split = script_params["Package"].split("*")
  array_split.delete(package_id)
  package_name = array_split.join("*")
  rlm_package_content_references = RlmUtilities.get_package_content_references(RLM_BASE_URL, RLM_USERNAME, RLM_PASSWORD, package_id)
  return rlm_package_content_references
end

def import_script_parameters
  { "render_as" => "Table" }
end