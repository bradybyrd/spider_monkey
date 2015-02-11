FactoryGirl.define do
  factory :request_package_content do
    association :request
    association :package_content
  end
end

