require 'spec_helper'

describe IntegrationCsvsController, :type => :controller do
  context "#create" do
    before(:each) do
      pending "undefined method `responds_to_parent'"
      @plan = create(:plan)
      @integration_csv = mock_model(IntegrationCsv)
    end

    it "returns validation errors" do
      post :create, {:plan_id => @plan.id}
      response.should render_template('misc/error_messages_for')
    end
  end
end
