require 'spec_helper'

describe 'v1/steps' do
  describe 'post v1/steps Usage of Script Draft State Objects ' do
    it 'is allowed' do
      user = create(:user, :root)
      request = create(:request)
      script  = create(:general_script,  aasm_state: 'draft')
      step_params = {name: 'Test Step',
                owner_id: user.id,
                owner_type: 'User',
                request_id: request.id,
                script_id: script.id}

      post v1_steps_path(step: step_params,format: :json, token: @user.api_key)

      expect(response.status).to eq 201
    end
  end

end