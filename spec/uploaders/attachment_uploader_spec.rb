require 'carrierwave/test/matchers'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AttachmentUploader do
pending "Java err\nrank 3" do
  include CarrierWave::Test::Matchers

  before do
    file_path = File.join(Rails.root, 'spec', 'fixtures', 'files', 'example.jpg')
    AttachmentUploader.enable_processing = false
    @upload = create(:upload)
    @uploader = AttachmentUploader.new(@upload, :attachment)
    @uploader.store!(File.open(file_path))
  end

  after do
    AttachmentUploader.enable_processing = false
    @uploader.remove!
  end

  it "should make the image readable only to the owner and not executable" do
    @uploader.should have_permissions(0644)
  end
end
end