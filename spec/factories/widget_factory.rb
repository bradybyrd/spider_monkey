FactoryGirl.define do
  factory :widget do
    association :user
    sequence :column do |x| x % 3 + 1 end
    sequence :row do |x| x % 10 + 1 end
    state true
    sequence :widget_name do |x| "widget_#{x}" end
  end
end
