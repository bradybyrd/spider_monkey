FactoryGirl.define do
  factory :script_argument do
    name 'action to execute'
    position 'A1:B1'
    argument 'action'
    argument_type 'in-text'
    is_private false
    is_required false
    association :script
  end
end

