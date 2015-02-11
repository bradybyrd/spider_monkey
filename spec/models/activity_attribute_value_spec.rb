require 'spec_helper'

describe ActivityAttributeValue do
  before(:each) do
    @activity_attribute_value = create(:activity_attribute_value)
  end

  describe "associations" do
    context "should belong_to" do
      it { @activity_attribute_value.should belong_to(:activity) }
      it { @activity_attribute_value.should belong_to(:value_object) }
      it { @activity_attribute_value.should belong_to(:activity_attribute) }
    end
  end

  describe "validations" do
    it 'requires presence of activity_attribute_id' do
      @activity_attribute_value.stub(:activity_attribute).and_return(double('activity_attribute').as_null_object)
      @activity_attribute_value.should validate_presence_of(:activity_attribute_id)
    end
    it 'skip presence of activity_id for not new_activity' do
      @activity_attribute_value.update_attributes(:new_activity => false)
      @activity_attribute_value.should validate_presence_of(:activity_id)
    end
    it 'presence of activity_id for new_activity' do
      @activity_attribute_value.update_attributes(:new_activity => true)
      @activity_attribute_value.should_not validate_presence_of(:activity_id)
    end
  end

  describe 'after initialize' do
    it 'should run the proper callback' do
      activity_attribute_value = ActivityAttributeValue.allocate
      activity_attribute_value.should_receive(:set_attr_default)
      activity_attribute_value.send(:initialize)
    end
  end
end
