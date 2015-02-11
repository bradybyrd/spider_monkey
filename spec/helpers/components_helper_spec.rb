require 'spec_helper'

describe ComponentsHelper do
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
  end

  context '#check_for_installed_comp' do
    it 'returns installed component name' do
      @step.update_attributes(installed_component_id: @installed_component.id)
      @step.save
      helper.check_for_installed_comp(@step, @component.name).should eql(@installed_component.name)
    end

    it 'returns component name' do
      helper.check_for_installed_comp(@step, @component.name).should eql(@component.name)
    end
  end

  it '#application_component_select_list' do
    @procedure = create(:procedure)
    @procedure.apps << @app
    @step.procedure_id = @procedure.id
    @step.protect_automation_tab = true
    @component2 = create(:component)
    @app_component2 = create(:application_component, :app => @app,
                                                     :component => @component2)
    @step.component_id = @component2.id
    @step.save
    @result = helper.application_component_select_list(@step, false)
    @result.should include("#{@component.name}")
    @result.should include("#{@component2.name}")
    @result.should include("selected='selected'")
    @result.should include("data-protect-automation=\"true\"")
  end
end
