FactoryGirl.define do
  factory :server do
    sequence(:name) { |n| "Server #{n}" }
    sequence(:dns) { |n| "host#{n}.streamstep.com" }
    sequence(:ip_address) { |n| "#{n}.#{n}.#{n}.#{n}" }
    os_platform { "centos5" }
  end
end

