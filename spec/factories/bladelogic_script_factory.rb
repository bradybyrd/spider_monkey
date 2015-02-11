script_content = <<-'SCRIPT_CONTENT'
###
# argument1:
#   name: the first argument
# argument2:
#   name: the second argument
###
#Close the file
@hand.close
SCRIPT_CONTENT

FactoryGirl.define do
  factory :bladelogic_script do
    sequence(:name) {|n| "blade logic script name #{n}" }
    content script_content
    authentication 'step'
    script_type 'BladelogicScript'
  end
end

