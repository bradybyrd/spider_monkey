require "spec_helper"

describe MapsHelper do
  before(:each) do
    @app = create(:app)
    @request1 = create(:request)
    @request1.apps << @app
    @step = create(:step, :request => @request1)
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                      :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                  :application_component => @app_component)
    @step.component_id = @component.id
    @step.save
    @property = create(:property)
    @value = create(:property_value, :property => @property,
                                     :value_holder_id => @installed_component.id,
                                     :value_holder_type => 'InstalledComponent')
  end

  context "#property_" do
    context "value" do
      it "returns field value" do
        helper.property_value(@app_env, @component, @property).should eql(@value.value)
      end

      it "returns ensure_space" do
        @app_env.stub(:installed_component_for).and_return(nil)
        helper.property_value(@app_env, @component, @property).should eql("&nbsp;")
      end
    end

    context "value_title" do
      it "returns field value" do
        helper.property_value_title(@app_env, @component, @property).should eql(@value.value)
      end

      it "returns ensure_space" do
        @app_env.stub(:installed_component_for).and_return(nil)
        helper.property_value_title(@app_env, @component, @property).should eql("&nbsp;")
      end
    end
  end

  it "#property_value_change_dates" do
    helper.property_value_change_dates(@app_env, [@component]).should eql([@value.created_at])
  end

  context "#servers_on_steps" do
    it "returns nothing" do
      helper.servers_on_steps(nil).should eql(nil)
    end
  end

  context "#components_on_steps" do
    it "returns components names" do
      helper.components_on_steps([@step]).should eql(@component.name)
    end

    it "returns nothing" do
      helper.components_on_steps(nil).should eql(nil)
    end
  end

  context "#print_component_level" do
    it "returns level_number" do
      helper.print_component_level(2, [@component], @component).should eql(2)
    end

    it "returns '&nbsp;'" do
      helper.print_component_level(2, [], @component).should eql('&nbsp;')
    end
  end

  context "#print_installed_component_version" do
    it "returns version" do
      @installed_component.version = 2
      helper.print_installed_component_version(@installed_component).should eql('2')
    end

    it "returns '&nbsp;'" do
      helper.print_installed_component_version(@installed_component).should eql('&nbsp;')
    end
  end
end