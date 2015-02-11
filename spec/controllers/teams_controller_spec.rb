require 'spec_helper'

describe TeamsController, :type => :controller do
  render_views

  before(:each) do
    @app =  create(:app)
    @team = create(:team)
  end

  #### common values
  model = Team
  factory_model = :team
  can_archive = false
  #### values for index
  models_name = 'teams'
  model_index_path = '_index'
  be_sort = true
  per_page = 30
  index_flash = "No Team"
  #### values for edit
  model_edit_path = '/teams'
  edit_flash = nil
  http_refer = nil

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)

  describe '#create' do
    it "success" do
      expect{post :create, {:team => {:name => "Team1",
                                      :app_ids => [@app.id]
                                      },
                            :check_box_selection => "#{@user.id}",
                            :format => 'js'}
      }.to change(Team, :count).by(1)
      response.should render_template('misc/redirect')
    end

    it "fails" do
      Team.stub(:new).and_return(@team)
      @team.stub(:save).and_return(false)
      expect{post :create, {:team => {:name => "Team1"},
                     :check_box_selection =>  @user.id}
      }.to change(Team, :count).by(0)
    end

    it 'creates a team and stores the app teams assignment' do
      user = @user
      app = create :app
      app.users = []
      group = create :group
      group.resources << user
      params = {team: {name: 'a wonderful name', app_ids: [app.id], group_ids: [group.id]} }

      expect(app.reload.users).to be_empty
      post(:create, params)
      expect(app.reload.users).to eq [user]
    end
  end

  context '#edit' do
    it 'allow edit of team if it is inactive' do
      team = create(:team)
      team.deactivate!
      get :edit, id: team
      response.should render_template('teams/edit')
    end
  end

  context "#update" do
    it "success" do
      put :update, {:id => @team.id,
                    :team => {:name => 'Team_changed',},
                    :check_box_selection => "#{@user.id}",
                    :format => 'js'}
      Team.find(@team.id).name.should eql('Team_changed')
      response.should render_template('misc/redirect')
    end

    it "fails" do
      Team.stub(:find).and_return(@team)
      @team.stub(:update_attributes).and_return(false)
      new_team = create(:team)
      new_team.deactivate!
      @controller.should_receive(:render_or_redirect?).with(false)
      lambda{put :update, {:id => new_team.id,
                    :team => {:name => 'Team_changed',},
                    :check_box_selection =>  new_team.id}
            }.should raise_error ActionView::MissingTemplate

    end
  end

  context "#destroy" do
    it "success for inactive team" do
      new_team = create(:team)
      new_team.deactivate!
      expect{delete :destroy, {:id => new_team.id, :format => 'js'}
            }.to change(Team, :count).by(-1)
      response.should render_template('misc/redirect')
    end

    it "fail for active team" do
      new_team = create(:team)
      expect{delete :destroy, {:id => new_team.id, :format => 'js'}
            }.to change(Team, :count).by(0)
      response.should render_template('misc/redirect')
    end
  end

  it "#app_user_list" do
    get :app_user_list, {:id => @team.id,
                         :render_omly_app_name => '1',
                         :app_id => @app.id}
    assigns(:app).should eql(@app)
    response.should render_template(:partial => "teams/forms/_user_role_list_by_app")
  end

  context "#get_user_list_of_groups" do
    before(:each) {
      @users = 6.times.collect{create(:user, :active => true)}
      @users.sort_by!{|el| el.name}
      @user_ids = "#{@users[0].id}"
      @users[1..5].each{|el| @user_ids = @user_ids + ",#{el.id}"}
    }

    it "return paginated Users" do
      post :get_user_list_of_groups, {:id => @team.id,
                                     :selection_type => 'Users',
                                     :user_ids => @user_ids,
                                     :format => "js"}
      @users[0..4].each{|el| assigns(:active_users).should include(el)}
      assigns(:active_users).should_not include(@users[5])
      response.should render_template('teams/update_user_list')
    end

    it "return Users of Groups" do
      @group = create(:group)
      @group.resources = @users
      @group_ids = "#{@group.id}"
      post :get_user_list_of_groups, {:id => @team.id,
                                      :selection_type => 'Groups',
                                      :group_ids => @group_ids}
      @users[0..4].each{|el| assigns(:active_users).should include(el)}
      assigns(:active_users).should_not include(@users[5])
    end
  end

  describe 'manage apps and groups in team' do
    let(:team) { create :team }
    let(:apps) { create_list :app, 2 }
    let(:groups) { create_list :group, 2 }
    let(:app_ids) { apps.map(&:id) }
    let(:group_ids) { groups.map(&:id) }

    describe 'manage groups' do
      it 'adds groups to a team without apps' do
        post :add_groups, { id: team.id, group_ids: group_ids }

        expect(team.reload.groups.size).to eq(2)
      end

      it 'removes groups from the team without apps' do
        post :add_groups, { id: team.id, group_ids: group_ids }
        post :remove_groups, { id: team.id, group_ids: group_ids }

        expect(team.reload.groups.size).to eq(0)
      end

      it 'add groups to the team' do
        group = create(:group)
        user = create(:user, groups: [group])
        app = create(:app)
        app.users = []
        team = create(:team, apps: [app])

        post :add_groups, { id: team.id, group_ids: group.id}

        expect(team.reload.groups.size).to eq(1)
        expect(app.reload.users.size).to eq(1)
      end

      it 'removes group from the team' do
        app, group_a, group_b = create_app_with_2_users_in_different_groups
        team_a = create(:team, apps: [app], groups: [group_a])
        team_b = create(:team, apps: [app], groups: [group_b])

        post :remove_groups, { id: team_a.id, group_ids: [group_a.id] }

        expect(team_a.reload.groups.size).to eq(0)
        expect(app.reload.users.size).to eq(1)
      end
    end

    describe 'manage apps' do
      it 'add apps to the team with groups and apps' do
        post :add_apps, { id: team.id, app_ids: app_ids }

        expect(team.reload.apps.size).to eq(2)
      end

      it 'removes apps from the team with groups and apps' do
        apps = create_list(:app, 2, teams: [build(:team)])
        team = create(:team)

        post :remove_apps, { id: team.id, app_ids: apps.map(&:id) }

        expect(team.reload.apps.size).to eq(0)
      end

      it 'add apps to the team with related users' do
        group = create(:group)
        user = create(:user, groups: [group])
        app = create(:app)
        new_app = create(:app)
        app.users = [user]
        new_app.users = []
        team = create(:team, apps: [app], groups: [group])

        post :add_apps, { id: team.id, app_ids: new_app.id}

        expect(team.reload.apps.size).to eq(2)
        expect(new_app.reload.users.size).to eq(1)
      end

      it 'removes apps in team with related users' do
        app, group_a, group_b = create_app_with_2_users_in_different_groups
        team_a = create(:team, apps: [app], groups: [group_a])
        team_b = create(:team, apps: [app], groups: [group_b])

        post :remove_apps, { id: team_a.id, app_ids: [app.id] }

        expect(team_a.reload.apps.size).to eq(0)
        expect(app.reload.users.size).to eq(1)
      end
    end
  end

  describe '#team_groups' do
    let!(:groups)         { create_list :group, 2 }
    let(:team)            { build :team }
    let(:per_page)        { AlphabeticalPaginator::DEFAULT_PER_PAGE }
    let(:expected_groups) { Group.order(:name).active.first(per_page) }

    it 'renders paginated groups' do
      get :team_groups, format: :js

      expect(assigns :groups).to match_array expected_groups
    end

    context 'with unsaved team' do
      it 'assigns a team' do
        get :team_groups, format: :js

        expect(assigns :team).to be_new_record
      end
    end

    context 'with saved team' do
      let(:team) { create :team }

      it 'finds the persisted team' do
        get :team_groups, id: team.id, format: :js

        expect(assigns :team).to eq team
      end
    end
  end

  describe '#default team', custom_roles: true do
    before(:each) do
      @default_group = create(:group, position: 1, name: '[default]')
      @default_app = create(:app, id: 0, name: '[default]')
      @default_team = create(:team, id: 0, name: '[default]', groups: [@default_group], apps: [@default_app])
    end

    it 'reset app_ids' do
      put :update, {id: @default_team.id, team: { app_ids: [] }}
      expect(@default_team.reload.apps.size).to eq(1)
    end

    it 'reset group_ids' do
      put :update, {id: @default_team.id, team: { group_ids: [] }}
      expect(@default_team.reload.groups.size).to eq(1)
    end

    it 'cannot be destroyed' do
      expect{
        delete :destroy, id: @default_team.id
      }.to_not change{Team.count}.by(-1)
    end

    it 'cannot be made inactive' do
      post :deactivate, id: @default_team.id

      expect(@default_team.active).to be_truthy
    end
  end

  def create_app_with_2_users_in_different_groups
    group_a = create(:group)
    group_b = create(:group)

    user_a = create(:user, groups: [group_a])
    user_b = create(:user, groups: [group_b])

    app = create(:app)
    app.users = [user_a, user_b]

    [app, group_a, group_b]
  end
end
