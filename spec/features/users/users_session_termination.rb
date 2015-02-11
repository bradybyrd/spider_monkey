require 'spec_helper'

feature 'User session termination', js: true do

  given!(:user) { create(:user, :non_root) }

  scenario 'need to login again' do
    sign_in user
    visit root_path

    expect(page).to have_logout_link

    terminate_session
    visit root_path

    expect(page).not_to have_logout_link
  end

  def have_logout_link
    have_link 'Logout'
  end

  def terminate_session
    user.update_column :terminate_session, true
  end

end
