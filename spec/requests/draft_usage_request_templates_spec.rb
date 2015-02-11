require 'spec_helper'

describe 'v1/requests' do
  describe 'post v1/requests Usage of RT Draft State Objects ' do
    it 'is allowed' do
      user = create(:user, :root)
      request_template = create(:request_template, aasm_state:'draft')
      environment = create(:environment)
      request_params = {name: 'Test Request',
                requestor_id: user.id,
                deployment_coordinator_id: user.id,
                request_template_id: request_template.id,
                environment_id: environment.id}

      post v1_requests_path(request: request_params,format: :json, token: @user.api_key)

      expect(response.status).to eq 201
    end
  end

end