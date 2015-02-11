FactoryGirl.define do
  factory :business_process do
    sequence(:name) { |n| "Standard Release #{n}" }
    label_color '#9ACD32'
    apps { [FactoryGirl.create(:app)] }
  end
end

