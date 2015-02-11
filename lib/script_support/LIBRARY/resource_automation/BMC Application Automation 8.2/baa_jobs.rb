###
# job_type:
#   name: Job Type
#   type: in-list-single
#   list_pairs: 0,Select|1,FileDeploy|2,PackageDeploy|3,NSHScriptJob|4,SnapshotJob|5,ComplianceJob|6,AuditJob
#   required: yes
###


require 'yaml'
require 'script_support/baa_utilities'

baa_config = YAML.load(SS_integration_details)

BAA_USERNAME = SS_integration_username
BAA_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)
BAA_ROLE = baa_config["role"]
BAA_BASE_URL = SS_integration_dns

def get_mapped_model_type(job_type)
  case job_type
  when "1", "FileDeploy"
    return "FILE_DEPLOY_JOB"
  when "2", "PackageDeploy"
    return "DEPLOY_JOB"
  when "3", "NSHScriptJob"
    return "NSH_SCRIPT_JOB"
  when "4", "SnapshotJob"
    return "SNAPSHOT_JOB"
  when "5", "ComplianceJob"
    return "COMPLIANCE_JOB"
  when "6", "AuditJob"
    return "AUDIT_JOB"
  end
end

def execute(script_params, parent_id, offset, max_records)

  if parent_id.blank?
    # root folder
    group = BaaUtilities.get_root_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, "JOB_GROUP")
    return [{ :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}] if group
    return []
  else
    data = []
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "JOB_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    groups = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], "SMART_JOB_GROUP")
    if groups
      groups.each do |group|
        data << { :title => group["name"], :key => "#{group["groupId"]}|#{group["objectId"]}|#{group["modelType"]}", :isFolder => true, :hasChild => true, :hideCheckbox => true}
      end
    end
    objects = BaaUtilities.get_child_objects_from_parent_group(BAA_BASE_URL, BAA_USERNAME, BAA_PASSWORD, BAA_ROLE, parent_id.split("|")[2], parent_id.split("|")[1], get_mapped_model_type(script_params["job_type"]))
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