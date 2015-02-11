require 'spec_helper'

describe TemporaryPropertyValue do
  before(:each) do
    @temp_prop_val = TemporaryPropertyValue.new
  end

  describe "validations" do
    it "validates presence of" do
      @temp_prop_val.should validate_presence_of(:property_id)
      @temp_prop_val.should validate_presence_of(:request_id)
      @temp_prop_val.should validate_presence_of(:original_value_holder_id)
      @temp_prop_val.should validate_presence_of(:original_value_holder_type)
    end
  end

  describe "associations" do
    it "belongs to" do
      @temp_prop_val.should belong_to(:step)
      @temp_prop_val.should belong_to(:request)
      @temp_prop_val.should belong_to(:property)
      @temp_prop_val.should belong_to(:original_value_holder)
    end
  end

end

