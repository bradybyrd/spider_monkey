require "spec_helper"

describe ApplicationComponentsHelper do
  it "#class_for_application_component_color" do
    @app_comp = create(:application_component, :app => create(:app),
                       :component => create(:component))
    helper.class_for_application_component_color(@app_comp).should eql('even_component_level')
  end
end