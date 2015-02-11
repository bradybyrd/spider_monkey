require 'script_support/baa_utilities'
require 'yaml'

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)
  if parent_id.blank?
    # root folder
    group = BaaUtilities.get_root_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, "DEPOT_GROUP")
    return [{ :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}] if group
    return []
  else
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, "DEPOT_GROUP", parent_id.split("|")[1], "DEPOT_GROUP")
    return [] if groups.nil?
    data = []
    groups.each do |group|
      data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true}
    end
    data
  end
end

def import_script_parameters
  { "render_as" => "Tree" }
end