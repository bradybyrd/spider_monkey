require "spec_helper"

describe BladelogicScriptsHelper do
  before(:each) do
    @script = create(:bladelogic_script)
    @argument = @script.arguments.first
    @app = create(:app)
    @request1 = create(:request)
    @request1.apps << @app
    @step1 = create(:step, :request => @request1)
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                      :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                  :application_component => @app_component)
    @value = 'val1'
  end

  it "#bladelogic_script_argument_value_input_display" do
    @argument.is_a?(ScriptArgument).should be_falsey
    helper.stub(:bladelogic_should_include_select_tag?).and_return(true)
    @result = helper.bladelogic_script_argument_value_input_display(@step1, @argument, @installed_component, @value)
    @result.should include("<div class=\"field\"><input class=\"step_script_argument\" id=\"bladelogic_script_argument_#{@argument.id}\"")
    @result.should include("name=\"argument[#{@argument.id}]\" type=\"text\" value=\"#{@value}\" />")
  end

  it "#bladelogic_script_argument_value_select_tag" do
    @result = helper.bladelogic_script_argument_value_select_tag(@step1, @argument, @installed_component, @value)
    @result.should include("<select class=\"step_script_argument\" id=\"bladelogic_script_argument_#{@argument.id}\"")
    @result.should include("name=\"argument[#{@argument.id}]\"></select>")
  end

  it "#bladelogic_should_include_select_tag?" do
    @argument.stub(:values_from_properties).and_return(2)
    helper.bladelogic_should_include_select_tag?(@argument, @installed_component).should be_truthy
  end

  context "#bladelogic_script_argument_value_input_tag" do
    it "returns password field" do
      @argument.stub(:is_private).and_return(true)
      @result = helper.bladelogic_script_argument_value_input_tag(@step1, @argument, @installed_component, @value)
      @result.should include("type=\"password\"")
    end

    it "returns text field" do
      @result = helper.bladelogic_script_argument_value_input_tag(@step1, @argument, @installed_component, @value)
      @result.should include("type=\"text\"")
    end
  end

  context "#bladelogic_script_argument_value_input_tag_value" do
    it "returns step value" do
      @step1.stub(:script_argument_property_value).and_return('val1')
      helper.bladelogic_script_argument_value_input_tag_value(@step1, @argument, @installed_component).should eql('val1')
    end

    it "returns values from properties" do
      @argument.stub(:values_from_properties).and_return(['val2'])
      helper.bladelogic_script_argument_value_input_tag_value(nil, @argument, @installed_component).should eql('val2')
    end
  end
end
