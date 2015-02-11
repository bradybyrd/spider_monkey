require "spec_helper"

describe PropertiesHelper do
  let(:property) { create(:property) }

  it "#field_disabled_on_step_creation?" do
    work_task = create(:work_task)
    property.stub(:entry_during_step_creation_on_work_task?).and_return(true)
    helper.field_disabled_on_step_creation?(work_task, property).should_not be_truthy
  end

  it "#property_value_input" do
    helper.property_value_input('name', property, 'val1').should include("input id=\"name_#{property.id}\"")
  end

  it "#property_value_label" do
    helper.property_value_label('name', property, 'val1').should include("<label for=\"name_#{property.id}\"")
  end

  describe "#property_value_input_field" do
    it "returns select" do
      property.stub(:multiple_default_values?).and_return(true)
      helper.property_value_input_field('name', property, 'val1,val2').should include("<option value=\"val2\" selected=\"selected\">")
    end

    it "returns password field" do
      property.stub(:is_private?).and_return(true)
      helper.property_value_input_field('name', property, 'val1').should include("name=\"name[#{property.id}]\" type=\"password\"")
    end

    it "returns text field" do
      helper.property_value_input_field('name', property, 'val1').should include("name=\"name[#{property.id}]\" type=\"text\"")
    end
  end

  describe "#property_value_label_field" do
    it "returns password field" do
      property.stub(:is_private?).and_return(true)
      helper.property_value_label_field('name', property, 'val1').should eql("<label for=\"name_#{property.id}\">********</label>")
    end

    it "returns text field" do
      helper.property_value_label_field('name', property, 'val1').should eql(label_tag("name[#{property.name}]", 'val1'))
    end
  end

  it "#property_value_in_place_input" do
    helper.property_value_in_place_input('name', property, 'val1').should include("<input id=\"name_#{property.id}\"")
  end

  it "#show_hide_buttons" do
    result = helper.show_hide_buttons
    result.should include('lock_delete.png')
    result.should include('lock.png')
  end
end