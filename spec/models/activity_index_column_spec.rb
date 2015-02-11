require 'spec_helper'

describe ActivityIndexColumn do
  before(:each) do
    @activity_idx_col = create(:activity_index_column)
  end

  describe "validations" do
    it { @activity_idx_col.should validate_presence_of(:activity_category_id) }
    it { @activity_idx_col.should validate_presence_of(:activity_attribute_column) }
  end

  it "should belong to" do
    @activity_idx_col.should belong_to(:activity_category)
  end

  describe "#methods" do
    it "should have #available_attributes" do
      ActivityIndexColumn.available_attributes.should == ActivityIndexColumn::AvailableAttributes.keys
    end

    it "should have #name" do
      @activity_idx_col.name.should == ActivityIndexColumn::AvailableAttributes[@activity_idx_col.activity_attribute_column]
    end
    it "#activity_attribute_method should not match ids" do
      @activity_idx_col.activity_attribute_method.should_not =~ /_id(s)?$/
    end
  end

  describe "callbacks" do
    it 'should run proper callback after save' do
      @activity_idx_col.should_receive(:set_position)
      @activity_idx_col.send(:save)
    end
  end
end
