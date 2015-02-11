FactoryGirl.define do
  factory :project_server do
    sequence(:name) { |n| "project_servers #{n}" }
    server_name_id 5
    server_url 'http://137.72.224.176:8080'
    username 'ss'
    password ''
    is_active true
  end
end

