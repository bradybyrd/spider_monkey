require 'spec_helper'

describe Reports::AccessController do
  context 'authorization' do
    context 'authorize fails' do
      describe 'GET index' do
        include_context 'mocked abilities', :cannot, :view, :access_reports

        it 'redirects to root' do
          get :index
          expect(response).to redirect_to root_path
        end
      end

      describe 'GET roles_map' do
        include_context 'mocked abilities', :cannot, :view, :roles_map_report

        it 'redirects to root' do
          get :roles_map
          expect(response).to redirect_to root_path
        end
      end

      describe 'POST roles_map_report' do
        include_context 'mocked abilities', :cannot, :view, :roles_map_report

        it 'redirects to root' do
          post :roles_map_report
          expect(response).to redirect_to root_path
        end
      end
    end
  end

  describe 'GET index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end
  end

  describe 'GET roles_map' do
    it 'renders roles_map' do
      get :roles_map
      expect(response).to render_template('roles_map')
    end

    it 'assigns @teams_for_select' do
      team = create(:team)
      get :roles_map
      expect(assigns(:teams_for_select)).to eq([team])
    end
  end

  describe 'POST roles_map_report' do
    it 'renders roles_map_report' do
      post :roles_map_report
      expect(response).to render_template(partial: 'reports/access/roles_map/_roles_map_report')
    end

    it 'renders roles_map_report as csv' do
      csv_data = 'Test'
      RolesMapCsv.any_instance.should_receive(:generate).and_return csv_data

      post :roles_map_report, { format: :csv }
      expect(response.body).to eq csv_data
    end
  end

  describe 'GET groups_options_for_teams' do
    it 'renders select options' do
      team = create(:team)
      group = create(:group)
      team.groups << group

      ApplicationController.helpers.should_receive(:options_from_collection_for_select).with([group], :id, :name)

      get :groups_options_for_teams, { team_ids: [team.id] }
    end

    it 'renders nothing' do
      get :groups_options_for_teams
      expect(response.body).to be_blank
    end
  end

  describe 'GET users_options_for_groups' do
    it 'renders select options' do
      group = create(:group)
      user = create(:user)
      group.users << user

      ApplicationController.helpers.should_receive(:options_from_collection_for_select).with([user], :id, :name)

      get :users_options_for_groups, { group_ids: [group.id] }
    end

    it 'renders nothing' do
      get :users_options_for_groups
      expect(response.body).to be_blank
    end
  end
end