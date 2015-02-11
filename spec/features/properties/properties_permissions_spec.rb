require 'spec_helper'

feature 'User on a properties page', custom_roles: true, js: true do
  given!(:user)         { create(:user, :non_root, :with_role_and_group, login: 'Jupiter') }
  given!(:property)     { create(:property, name: 'Neptune') }
  given!(:permissions)  { user.groups.first.roles.first.permissions }
  given(:permission_to) do
    {
        property: {
            list:                   create(:permission, subject: 'Property', action: 'list', name: 'List'),
            create:                 create(:permission, subject: 'Property', action: 'create', name: 'Create'),
            edit:                   create(:permission, subject: 'Property', action: 'edit', name: 'Edit'),
            make_active_inactive:   create(:permission, subject: 'Property', action: 'make_active_inactive',
                                           name: 'Make Active and Inactive')
        }
    }
  end

  background do
    sign_in(user)
  end

  context 'with the appropriate permission' do

    scenario 'sees the list of the properties' do
      permissions << permission_to[:property][:list]

      visit properties_path

      expect(page).to have_css('div#properties > table')
      expect(page).to have_content(property.name)
    end

    scenario 'creates a new property' do
      property_name  = 'It is a marvelous property'
      permissions       << permission_to[:property][:list]
      permissions       << permission_to[:property][:create]

      visit properties_path

      click_on_create_property_image_button

      fill_in :property_name, with: property_name
      click_on I18n.t(:create)
      wait_for_ajax

      expect(page).to have_content property_created_message
      expect(page).to have_content property_name
    end

    scenario 'edits the property' do
      permissions << permission_to[:property][:list]
      permissions << permission_to[:property][:edit]

      visit properties_path

      click_on I18n.t(:edit)
      fill_in :property_name, with: 'A better name'
      click_on I18n.t(:update)
      wait_for_ajax

      expect(finished_all_ajax_requests?).to be_truthy
      expect(page).to have_content property_updated_message
      expect(page).to have_content property.name
    end

    scenario 'makes property active and inactive' do
      permissions << permission_to[:property][:list]
      permissions << permission_to[:property][:make_active_inactive]

      visit properties_path

      expect(page).to have_link(I18n.t(:make_inactive))

      click_on I18n.t(:make_inactive)

      expect(page).to have_link(I18n.t(:make_active))
      expect(property.reload).not_to be_active

      click_on I18n.t(:make_active)

      expect(page).to have_link(I18n.t(:make_inactive))
      expect(current_path).to eq properties_path
      expect(property.reload).to be_active
    end

  end
end


def property_created_message
  I18n.t(:'activerecord.notices.created', model: I18n.t('activerecord.models.property'))
end

def property_updated_message
  I18n.t(:'activerecord.notices.updated', model: I18n.t('activerecord.models.property'))
end

def click_on_create_property_image_button
  find(:css, 'img[alt="Create_property"]').click
end
