require 'spec_helper'

feature 'User on a dashboard page', js: true do
  scenario 'sort the application by name' do
    user = create(:user)
    create(:app, name: 'a_application')
    create(:app, name: 'z_application')

    sign_in user
    visit dashboard_path

    expect(app_names).to be_sorted_asc

    click_on_table_header_to_sort_app_by_name

    expect(app_names).to be_sorted_desc
  end

  def click_on_table_header_to_sort_app_by_name
    find("table#my_applications_#{1} th", text: I18n.t('table.name')).click
  end

  def be_sorted_asc
    eq %w(a_application z_application)
  end

  def be_sorted_desc
    eq %w(z_application a_application)
  end

  def apps
    all("table#my_applications_#{1} tr a strong")
  end

  def app_names
    apps.map(&:text)
  end
end