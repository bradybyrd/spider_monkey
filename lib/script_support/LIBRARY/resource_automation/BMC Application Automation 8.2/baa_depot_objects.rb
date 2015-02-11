###
#
# depot_object_type:
#   name: Depot Object Type
#   type: in-list-single
#   list_pairs: 0,Select|1,BLPackage|2,AixPatch|3,AixPackage|4,HPProduct|5,HPBundle|6,HPPatch|7,LinuxRPM|8,SolarisPatch|9,SolarisPackage|10,WindowsHotfix|11,WindowsSP|12,WindowsMSI|13,InstallShield
#   required: yes
###

require 'yaml'
require 'script_support/baa_utilities'

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns

def get_mapped_model_type(depot_object_type)
  mapped_model_type = ""
  case depot_object_type
  when "1", "BLPackage"
    mapped_model_type = "BLPACKAGE"
  when "2", "AixPatch"
    mapped_model_type = "AIX_PATCH_INSTALLABLE"
  when "3", "AixPackage"
    mapped_model_type = "AIX_PACKAGE_INSTALLABLE"
  when "4", "HPProduct"
    mapped_model_type = "HP_PRODUCT_INSTALLABLE"
  when "5", "HPBundle"
    mapped_model_type = "HP_BUNDLE_INSTALLABLE"
  when "6", "HPPatch"
    mapped_model_type = "HP_PATCH_INSTALLABLE"
  when "7", "LinuxRPM"
    mapped_model_type = "RPM_INSTALLABLE"
  when "8", "SolarisPatch"
    mapped_model_type = "SOLARIS_PATCH_INSTALLABLE"
  when "9", "SolarisPackage"
    mapped_model_type = "SOLARIS_PACKAGE_INSTALLABLE"
  when "10", "WindowsHotfix"
    mapped_model_type = "HOTFIX_WINDOWS_INSTALLABLE"
  when "11", "WindowsSP"
    mapped_model_type = "SERVICEPACK_WINDOWS_INSTALLABLE"
  when "12", "WindowsMSI"
    mapped_model_type = "MSI_WINDOWS_INSTALLABLE"
  when "13", "InstallShield"
    mapped_model_type = " INSTALLSHIELD_WINDOWS_INSTALLABLE"
  end
  mapped_model_type
end

def execute(script_params, parent_id, offset, max_records)

  if parent_id.blank?
    # root folder
    group = BaaUtilities.get_root_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, "DEPOT_GROUP")
    return [{ :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}] if group
    return []
  else
    data = []
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "DEPOT_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "SMART_DEPOT_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    objects = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], get_mapped_model_type(script_params["depot_object_type"]))
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