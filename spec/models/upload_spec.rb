################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe Upload do
pending "Java errors\nrank 2" do

  describe "delegations" do
    subject { build(:upload) }

    it { should respond_to :user_name }
  end

  describe 'validations' do
    let(:upload) { build(:upload) }

    it "should not allow attachments greater than 5 megabytes" do
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'files', 'image_5mb.tif')
      upload.attachment.store!(File.open(file_path))
      upload.should_not be_valid
      upload.errors.messages[:attachment].should include('is too big (should be at most 5 MB)')
    end

    it "should allow attachments smaller than 5 megabytes" do
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'files', 'example.jpg')
      upload.attachment.store!(File.open(file_path))
      upload.should be_valid
      upload.errors.messages[:attachment].should be_blank
    end
  end

  describe 'callbacks' do
    describe 'before_destroy #archive_step_attachments' do
      it 'removes step attachment and updates record for history' do
        requestor = create(:requestor)
        Upload.any_instance.should_receive(:archive_step_attachments).and_call_original
        User.stub(:current_user).and_return(requestor)
        upload = create(:upload, owner_type: 'Step', user: create(:user))
        upload.attachment.present?.should eq true
        upload.destroy
        upload.attachment.present?.should eq false
        upload.attributes.symbolize_keys.should include(user_id: requestor.id, deleted: true)
      end

      it 'removes record for other types' do
        Upload.any_instance.should_receive(:archive_step_attachments).and_call_original
        upload = create(:upload)
        expect{ upload.destroy }.to change(Upload, :count).by(-1)
      end
    end
  end

  describe '.default_scope' do
    it 'returns only unarchived records' do
      upload = create(:upload)
      create(:upload, deleted: true)
      Upload.all.should eq [upload]
    end
  end

  describe '.archieved_attachments' do
    it 'returns only archieved records ordered by updated_at field' do
      upload = create(:upload, deleted: true, updated_at: Time.now - 1.hour)
      upload_last = create(:upload, deleted: true, updated_at: Time.now)
      create(:upload)
      Upload.archieved_attachments.should eq [upload, upload_last]
    end
  end
end
end