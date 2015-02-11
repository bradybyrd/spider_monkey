require 'spec_helper'

feature 'User opens Problem Trend Report page', custom_roles: true do
  scenario 'and sees the filters' do
    user = create(:user, :root, login: 'Saturn')
    sign_in user
    visit problem_trend_report_page

    expect(page).to have_filters
  end

  def problem_trend_report_page
    reports_path(report_type: 'problem_trend_report')
  end

  def have_filters
    have_css '#filterSection'
  end

end
