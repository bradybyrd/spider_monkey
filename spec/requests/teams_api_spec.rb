require 'spec_helper'

base_url =  '/v1/teams'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :team }
  let(:xml_root) { 'team' }

  before :all do
    @user         = create(:user, :root)
    @token        = @user.api_key
  end

  context 'with existing teams and valid api key' do
    before(:each)  do
      @app_1          = create(:app)
      @app_2          = create(:app)
      @group_1        = create(:group)
      @group_2        = create(:group)
      @user_1         = create(:user)
      @user_2         = create(:user)
      @user_manage    = create(:user)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @team_1 = create(:team)
        @team_2 = create(:team, name: 'fire_in_the_hole')
        @team_3 = create(:team, name: 'mad name', active: false)

        @active_team_ids = [@team_2.id, @team_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all teams except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_team_ids)
        end

        it 'should return all teams except inactive' do
          param   = {filters: {active: true}}

          jget param

          should have_json('number.id').with_values(@active_team_ids)
        end

        it 'should return all teams inactive' do
          param   = {filters: {inactive: true}}

          jget param

          should have_json('number.id').with_values([@team_3.id])
        end

        it 'should return all teams' do
          param   = {filters: {inactive: true, active: true}}

          jget param

          should have_json('number.id').with_values([@team_3.id] + @active_team_ids)
        end

        it 'should return all inactive teams' do
          param   = {filters: {inactive: true, active: false}}

          jget param

          should have_json('number.id').with_value(@team_3.id)
        end

        it 'should return team by name' do
          param   = {filters: {name: 'fire_in_the_hole'}}

          jget param

          should have_json('number.id').with_value(@team_2.id)
        end

        it 'should not return inactive team by name' do
          param   = {filters: {name: 'mad name'}}

          jget param

          should == " "
        end

        it 'should return inactive team by name if it is specified' do
          param   = {filters: {name: 'mad name', inactive: true, active: false}}

          jget param

          should have_json('number.id').with_value(@team_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'teams/team'}

        subject { response.body }

        it 'should return all teams except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_team_ids)
        end

        it 'should return all teams except inactive' do
          param   = {filters: {active: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_team_ids)
        end

        it 'should return all teams inactive' do
          param   = {filters: {inactive: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@team_3.id])
        end

        it 'should return all teams' do
          param   = {filters: {inactive: true, active: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@team_3.id] + @active_team_ids)
        end

        it 'should return all inactive teams' do
          param   = {filters: {inactive: true, active: false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@team_3.id)
        end

        it 'should return team by name' do
          param   = {filters: {name: 'fire_in_the_hole'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@team_2.id)
        end

        it 'should not return inactive team by name if that was not specified' do
          param   = {filters: {name: 'mad name'}}

          xget param

          should == " "
        end

        it 'should return inactive team by name if it is specified' do
          param   = {filters: {name: 'mad name', inactive: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@team_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @team_1 = create(:team)
        @team_2 = create(:team)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@team_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return team' do
          jget

          should have_json('number.id').with_value(@team_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@team_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return team' do
          xget

          should have_xpath('team/id').with_text(@team_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:created_team) { Team.last }

      context 'with valid params' do
        let(:param)             { {name: 'DiesIrae',
                                   active: false,
                                   app_ids: [@app_1.id, @app_2.id],
                                   group_ids: [@group_1.id, @group_2.id],
                                   user_id: @user_manage.id
        } }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('string.created_at')  }
          it { should have_json('string.updated_at')  }
          it { should have_json('array.apps')         }
          it { should have_json('array.groups')       }
          it { should have_json('number.user_id')     }

          it 'should create team with name' do
            should have_json('string.name').with_value('DiesIrae')
          end

          it 'should create inactive team' do
            should have_json('boolean.active').with_value(false)
          end

          it 'should create team with two apps' do
            should have_json('array.apps number.id').with_values([@app_1.id, @app_2.id])
            created_team.apps.should match_array [@app_1, @app_2]
          end

          it 'should create team with two groups' do
            should have_json('array.groups number.id').with_values([@group_1.id, @group_2.id])
            created_team.groups.should match_array [@group_1, @group_2]
          end

          it 'should create team with managed by user' do
            should have_json('number.user_id').with_value(@user_manage.id)
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(root: xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/created-at")  }
          it { should have_xpath("#{xml_root}/updated-at")  }
          it { should have_xpath("#{xml_root}/apps")        }
          it { should have_xpath("#{xml_root}/groups")      }
          it { should have_xpath("#{xml_root}/user-id")     }

          it 'should update team with name' do
            should have_xpath("#{xml_root}/name").with_text('DiesIrae')
          end

          it 'should update inactive team' do
            should have_xpath("#{xml_root}/active").with_text(false)
          end

          it 'should create team with two apps' do
            should have_xpath("#{xml_root}/apps/app/id").with_texts([@app_1.id, @app_2.id])
            created_team.apps.should match_array [@app_1, @app_2]
          end

          it 'should create team with two groups' do
            should have_xpath("#{xml_root}/groups/group/id").with_texts([@group_1.id, @group_2.id])
            created_team.groups.should match_array [@group_1, @group_2]
          end

          it 'should create team with managed by user' do
            should have_xpath("#{xml_root}/user-id").with_text(@user_manage.id)
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @team = create(:team) }

        let(:param) { {name: Team.last.name} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:updated_team) { Team.find(@team.id) }
      let(:url)          { "#{base_url}/#{@team.id}?token=#{@user.api_key}" }

      context 'with valid params' do
        let(:environment) { create(:environment) }
        let(:role) { create(:role) }
        let(:param) { {name: 'AgnusDei',
                       active: true,
                       app_ids: [@app_1.id],
                       group_ids: [@group_1.id],
                       role_environment_mappings: [{
                         group_id: @group_1.id,
                         app_id: @app_1.id,
                         environment_id: environment.id,
                         role_id: role.id
                       }],
                       user_id: @user_manage.id
        } }

        context 'JSON' do
          before :each do
            params       = {json_root => param}.to_json
            @team = create(:team, active: false)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update team with name' do
            should have_json('string.name').with_value('AgnusDei')
          end

          it 'should update inactive team' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should create team with app' do
            should have_json('array.apps number.id').with_value(@app_1.id)
            updated_team.apps.should match_array [@app_1]
          end

          it 'should create team with group' do
            should have_json('array.groups number.id').with_value(@group_1.id)
            updated_team.groups.should match_array [@group_1]
          end

          it 'should create team with managed by user' do
            should have_json('number.user_id').with_value(@user_manage.id)
          end

          it 'should create a TeamGroupAppEnvRole with the relevant models' do
            should have_json('array.team_group_app_env_roles object number.role_id').
              with_value(role.id)
            should have_json('array.team_group_app_env_roles object number.team_id').
              with_value(@team.id)
            should have_json('array.team_group_app_env_roles object number.group_id').
              with_value(@group_1.id)
            should have_json('array.team_group_app_env_roles object number.app_id').
              with_value(@app_1.id)
            should have_json('array.team_group_app_env_roles object number.environment_id').
              with_value(environment.id)
          end
        end

        context 'XML' do
          before :each do
            params  = param.to_xml(root: xml_root)
            @team   = create(:team, active: false)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should create team with name' do
            should have_xpath("#{xml_root}/name").with_text('AgnusDei')
          end

          it 'should create inactive team' do
            should have_xpath("#{xml_root}/active").with_text(true)
          end

          it 'should create team with app' do
            should have_xpath("#{xml_root}/apps/app/id").with_text(@app_1.id)
            updated_team.apps.should match_array [@app_1]
          end

          it 'should create team with group' do
            should have_xpath("#{xml_root}/groups/group/id").with_text(@group_1.id)
            updated_team.groups.should match_array [@group_1]
          end

          it 'should create team with managed by user' do
            should have_xpath("#{xml_root}/user-id").with_text(@user_manage.id)
          end

          it 'should create a TeamGroupAppEnvRole with the relevant models' do
            should have_xpath("#{xml_root}/team-group-app-env-roles/team-group-app-env-role/role-id").
              with_text(role.id)
            should have_xpath("#{xml_root}/team-group-app-env-roles/team-group-app-env-role/team-id").
              with_text(@team.id)
            should have_xpath("#{xml_root}/team-group-app-env-roles/team-group-app-env-role/group-id").
              with_text(@group_1.id)
            should have_xpath("#{xml_root}/team-group-app-env-roles/team-group-app-env-role/app-id").
              with_text(@app_1.id)
            should have_xpath("#{xml_root}/team-group-app-env-roles/team-group-app-env-role/environment-id").
              with_text(environment.id)
          end
        end
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:team)
          @team = create(:team)
        end

        let(:param) { {name: Team.first.name} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @team = create(:team)
        Team.stub(:find).with(@team.id).and_return @team
      end

      let(:url) {"#{base_url}/#{@team.id}?token=#{@user.api_key}"}
      let(:params) {
        { 'json' => { id: @team.id }.to_json,
          'xml' => create_xml {|xml| xml.id @team.id} }
      }

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          mimetype_headers = eval "#{mimetype}_headers"

          delete url, params[mimetype], mimetype_headers

          response.status.should == 202
          @team.active.should == false
        end
      end
    end
  end

  context 'with invalid api key' do
    let(:token)     { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, response_code: 403
  end

  context 'with no existing teams' do
    before { Team.delete_all }
    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, response_code: 404, mimetypes: mimetypes
  end
end
