require 'spec_helper'

describe 'Usage of Script Draft State Objects', custom_roles: true do

  before { GlobalSettings.stub(:automation_enabled?).and_return(true) }

  it 'is allowed', js: true do
    user = create(:user, :root, :with_role_and_group)
    request = given_request_assigned_to_user(user)
    script  = create(:general_script,  aasm_state: 'released')
    step = create(:step, request: request, script: script)

    request.aasm_state = 'planned'
    request.save!

    script.aasm_state = 'draft'
    script.save!

    sign_in(user)
    visit request_path(request)
    start_button.click

    expect(page).not_to have_content 'Aasm state Usage of objects in DRAFT state is not allowed'

  end

  def start_button
    page.find('div.request_start_button a.anyStepsCheckedtrue')
  end

  def given_request_assigned_to_user(user)
    environment = create(:environment)
    request = create(:request, :with_assigned_app, user: user, environment: environment)
    app = request.apps.first
    app.environments = [environment]
    request
  end

end
