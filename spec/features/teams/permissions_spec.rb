require 'spec_helper'

feature 'Teams page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:team) { create(:team) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'View dashboard tab', action: :view, subject: :dashboard_tab ),
      create(:permission, name: 'System tab view', action: :view, subject: :system_tab)
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:view_teams_permission) { create(:permission, name: 'View teams list', action: :list, subject: 'Team') }
  given(:create_team_permission) { create(:permission, name: 'Create team', action: :create, subject: 'Team') }
  given(:edit_team_permission) { create(:permission, name: 'Edit team', action: :edit, subject: 'Team') }
  given(:make_inactive_team_permission) { create(:permission, name: 'Make active/inactive team', action: :make_active_inactive, subject: 'Team') }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe '"Team" tab' do
    scenario 'not available when user hasn"t "list teams" permission' do
      visit teams_path

      within '#primaryNav' do
        expect(page).to have_no_content 'Teams'
      end
    end

    scenario 'available when user has "list teams" permission' do
      permissions << view_teams_permission
      visit teams_path

      within '#primaryNav' do
        expect(page).to have_link 'Teams'
      end
    end
  end

  describe 'teams index page' do
    context 'teams list' do
      scenario 'when does not user has any team permissions' do
        visit teams_path

        expect(page).not_to have_css('#teams')
        expect(page).not_to have_content(team.name)
      end

      scenario 'when user has "list teams" permission user can view teams list' do
        permissions << view_teams_permission
        visit teams_path

        expect(page).to have_css('#teams')
        expect(page).to have_content(team.name)
      end
    end

    context '"Create Team" button' do
      background do
        permissions << view_teams_permission
      end

      scenario 'when does not user has any team permissions except view list' do
        visit teams_path
        expect(page).not_to have_css('.create_team')

        visit new_team_path
        expect(page).not_to have_content('Create Team')
      end

      scenario 'when user has "create team" permission user can see "Create team" button' do
        permissions << create_team_permission
        visit teams_path

        expect(page).to have_css('.create_team')
        page.find('.create_team').click
        expect(page).to have_content('Create Team')
      end
    end

    context '"Edit Team" link' do
      background do
        permissions << view_teams_permission
      end

      scenario 'when does not user has any team permissions except view list' do
        visit teams_path
        expect(page).not_to have_css('.edit_team')

        visit edit_team_path(team)
        expect(page).not_to have_content(team.name)
      end

      scenario 'when user has "edit team" permission user can see "Edit" link' do
        permissions << edit_team_permission
        visit teams_path

        expect(page).to have_css('.edit_team')
        page.find("#team_#{ team.id } .edit_team").click
        expect(page).to have_content(team.name)
      end
    end

    context '"Make active/inactive" link' do
      background do
        permissions << view_teams_permission
      end

      scenario 'when does not user has any team permissions except view list' do
        visit teams_path
        expect(page).not_to have_css('.make_inactive_team')
        expect(page).not_to have_content('Inactive')
      end

      scenario 'when user has "make default team" permission user can see "Make Default" link' do
        permissions << make_inactive_team_permission
        visit teams_path

        expect(page).to have_css('.make_inactive_team')
        page.find("#team_#{ team.id } .make_inactive_team").click
        expect(page).to have_content('Inactive')
      end
    end
  end

end
