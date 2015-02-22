require 'spec_helper'

describe IntegrationCsvsController, type: :controller do
  context '#create' do
    it 'returns validation errors' do
      pending "undefined method `responds_to_parent'"
      plan = create(:plan)
      @integration_csv = mock_model(IntegrationCsv)
      post :create, {:plan_id => plan.id}
      expect(response).to render_template('misc/error_messages_for')
    end
  end
end
