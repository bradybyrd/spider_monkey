require "spec_helper"

describe ReleaseContentItem do

  before(:each) do
    @release_c_item = ReleaseContentItem.new
  end

  let(:ReleaseContentItem_with_SoftDelete) {
    ReleaseContentItem.new do
      include ReleaseContentItem::SoftDelete
    end
  }

  describe "validations" do
    it { @release_c_item.should validate_presence_of(:name) }
    it { @release_c_item.should validate_presence_of(:description) }

    it "should validate presence" do
      release_c_item = ReleaseContentItem.create({})
      release_c_item.should_not be_valid
    end
  end

  describe "associations" do
    it { @release_c_item.should belong_to(:plan) }
    it { @release_c_item.should belong_to(:integration_project) }
    it { @release_c_item.should belong_to(:integration_release) }
    it { @release_c_item.should have_many(:steps_release_content_items) }
    it { @release_c_item.should have_many(:request_steps) }
    it { @release_c_item.should have_many(:steps) }
  end
end
