require 'spec_helper'

feature 'Users pagination', js: true do

  given!(:user) { create(:user, :root) }

  background do
    sign_in user
  end

  scenario ' - clicking on "Next" link moves the page to next set of users' do
    create_list(:user, 31)
    user_on_last_page = User.by_last_name.last
    visit users_path

    user_paginator.click

    expect(page).to have_text(user_on_last_page.name)
  end

  def user_paginator
    find(next_link_css_text)
  end

  def next_link_css_text
    '.user-top-paginator [data-role="next-page-link"]'
  end

end
