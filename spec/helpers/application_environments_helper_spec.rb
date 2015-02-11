require "spec_helper"

describe ApplicationEnvironmentsHelper do
  it "#class_for_environment_color" do
    @app_env = create(:application_environment, :app => create(:app),
                                                :environment => create(:environment))
    helper.class_for_environment_color(@app_env).should eql('environment_color_1')
  end
end
