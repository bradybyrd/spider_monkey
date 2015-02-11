script_content = <<-'SCRIPT_CONTENT'
###
# argument1:
#   name: the first argument
# argument2:
#   name: the second argument
###
echo 1
#Close the file
@hand.close
SCRIPT_CONTENT
resource_content = <<-SCRIPT_CONTENT
  def execute(script_params, parent_id, offset, max_records)
  end
SCRIPT_CONTENT

FactoryGirl.define do
  factory :script do
    sequence(:name) { |n| "hudson script name #{n}" }
    content script_content
    created_at '2011-12-22 06:23:02'
    updated_at '2011-12-14 06:23:02'
    aasm_state 'released'
    is_import true
    factory :general_script do
      automation_category 'General'
      automation_type 'Automation'
      description 'general echoing script'
    end
    factory :resource_automation_script do
      automation_category 'RLM Deployment Engine'
      automation_type 'ResourceAutomation'
      description 'general echoing script'
      content resource_content
      sequence(:unique_identifier) { |n| "ResourceId#{n}" }
    end
  end
end

