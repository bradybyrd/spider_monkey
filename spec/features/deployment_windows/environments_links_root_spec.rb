require 'spec_helper'

feature 'Environments links for not assigned applications', custom_roles: true, role_per_env: true do
  given!(:user) { create(:user, :root ) }
  given!(:environment1) { create(:environment, name: 'Env1') }
  given!(:environment2) { create(:environment, name: 'Env2') }
  given!(:app1) { create(:app, environments: [environment1]) }
  given!(:app2) { create(:app, environments: [environment2]) }
  given!(:team) { create(:team, groups: user.groups, apps: [app1]) }

  given!(:deployment_window_series) { create(:deployment_window_series, :with_occurrences, environment_ids: [environment1.id, environment2.id], environment_names: [environment1.name, environment2.name].join(', ')) }

  background do
    ## Only assign one to user
    user.apps << app1

    sign_in user
  end

  scenario 'all are shown as links' do
    visit deployment_window_series_index_path

    expect(page).to have_link('Env1')
    expect(page).to have_link('Env2')
    expect(page).to have_content('Env2')
  end


end
