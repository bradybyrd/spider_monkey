include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :upload do
    owner_id 1
    owner_type 'Request'
    deleted false
    attachment { fixture_file_upload(File.join(Rails.root, 'spec', 'fixtures', 'files', 'example.jpg'), "image/jpeg", :binary) }
  end
end

