require 'yaml'
require 'script_support/baa_utilities'

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns

def execute(script_params, parent_id, offset, max_records)

  if parent_id.blank?
    # root folder
    group = BaaUtilities.get_root_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, "STATIC_COMPONENT_GROUP")
    return [{ :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}] if group
    return []
  else
    data = []
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "STATIC_COMPONENT_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "SMART_COMPONENT_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    objects = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "COMPONENT")
    if objects
      objects.each do |object|
        data << { :title => object["name"], :key => "#{object["name"]}|#{object["objectId"]}|#{object["dbKey"]}", :isFolder => false }
      end
    end
    return data
  end

end

def import_script_parameters
  { "render_as" => "Tree" }
end