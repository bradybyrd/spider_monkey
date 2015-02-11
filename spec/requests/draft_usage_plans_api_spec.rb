require 'spec_helper'

describe 'v1/plans' do
  describe 'post v1/plans Usage of Plan Template Draft State Objects ' do
    it 'is allowed' do
      user = create(:user, :root)
      plan_template=  create(:plan_template,aasm_state: 'draft')
      plan_params = { name: plan_template.name, plan_template_id: plan_template.id}

      post v1_plans_path(plan: plan_params,format: :json, token: @user.api_key)

      expect(response.status).to eq 201
    end
  end

end