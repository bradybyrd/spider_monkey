require 'spec_helper'

feature 'Request Templates page has status', js: true do
  given!(:user) { create(:user, :root) }
  given!(:request_template) { create(:request_template, aasm_state: 'draft') }

  background do
    sign_in user
  end

  scenario 'changing states on list page' do
    visit request_templates_path
    expect(page).to have_content(request_template.name)
    expect(page).to have_state 'Draft'

    move_state_right(request_template)
    expect(page).to have_state 'Pending'
    expect(page).to have_button 'Create Request'

    move_state_right(request_template)
    expect(page).to have_state 'Released'

    move_state_right(request_template)
    expect(page).to have_state 'Retired'

    move_state_right(request_template)
    expect(page).to have_archived_state(request_template)

    click_on 'Unarchive'
    expect(page).to have_state 'Retired'
  end

  scenario 'should not be able to create Requests with RTs in draft status' do
    visit request_templates_path

    expect(page).to have_content(request_template.name)
    expect(page).to have_state 'Draft'
    expect(page).not_to have_button 'Create Request'

    move_state_right(request_template)
    expect(page).to have_state 'Pending'
    expect(page).to have_button 'Create Request'

    move_state_left(request_template)
    expect(page).to have_state 'Draft'
    expect(page).not_to have_button 'Create Request'

  end


  def move_state_right(request_template)
    within "#state_list_#{ request_template.id }" do
      click_on '>>'
    end
  end

  def move_state_left(request_template)
    within "#state_list_#{ request_template.id }" do
      click_on '<<'
    end
  end

  def have_state(state)
    have_css("#td_state_#{ request_template.id }", text: state)
  end

  def have_archived_state(request_template)
    have_content(request_template.name + ' [archived')
  end

end