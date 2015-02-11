require 'spec_helper'

base_url =  '/v1/groups'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :group }
  let(:xml_root) { 'group' }
  let(:token) { @user.api_key }

  before :all do
    @root_group = create(:group, root: true)
    @user = create(:user, groups: [@root_group])
  end

  context 'with existing groups and valid api key' do
    before(:each)  do
      @team = create(:team)
      @resource = create(:user)
    end

    let(:url) { "#{base_url}?token=#{token}" }

    describe "GET #{base_url}" do
      let(:xml_root) {'groups/group'}

      before(:each) do
        Group.delete_all

        @group_1 = create(:group, :name => 'active root group', root: true)
        @group_2 = create(:group, :name => 'Abyssus abyssum invocat')
        @group_3 = create(:group, :name => 'mad', :active => false)

        @user = create(:user, groups: [@group_1])

        @active_group_ids = [@group_2.id, @group_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all groups except inactive(by default)' do
          jget

          should have_json('array:root > object > number.id').with_values(@active_group_ids)
        end

        it 'should return all groups except inactive' do
          jget({:filters => {:active => true}})

          should have_json('array:root > object > number.id').with_values(@active_group_ids)
        end

        it 'should return all groups inactive' do
          jget({:filters => {:inactive => true}})

          should have_json('array:root > object > number.id').with_values([@group_3.id])
        end

        it 'should return all groups' do
          jget({:filters => {:inactive => true, :active => true}})

          should have_json('array:root > object > number.id').with_values([@group_3.id] + @active_group_ids)
        end

        it 'should return all inactive groups' do
          jget({:filters => {:inactive => true, :active => false}})

          should have_json('array:root > object > number.id').with_value(@group_3.id)
        end

        it 'should return group by name' do
          jget({:filters => {:name => 'Abyssus abyssum invocat'}})

          should have_json('array:root > object > number.id').with_value(@group_2.id)
        end

        it 'should not return inactive group by name' do
          jget({:filters => {:name => 'mad'}})

          should == " "
        end

        it 'should return inactive group by name if it is specified' do
          jget({:filters => {:name => 'mad', :inactive => true}})

          should have_json('number.id').with_value(@group_3.id)
        end
      end

      context 'XML' do
        subject { response.body }

        it 'should return all groups except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_group_ids)
        end

        it 'should return all groups except inactive' do
          xget({:filters => {:active => true}})

          should have_xpath("#{xml_root}/id").with_texts(@active_group_ids)
        end

        it 'should return all groups inactive' do
          xget({:filters => {:inactive => true}})

          should have_xpath("#{xml_root}/id").with_texts([@group_3.id])
        end

        it 'should return all groups' do
          xget({:filters => {:inactive => true, :active => true}})

          should have_xpath("#{xml_root}/id").with_texts([@group_3.id] + @active_group_ids)
        end

        it 'should return all inactive groups' do
          xget({:filters => {:inactive => true, :active => false}})

          should have_xpath("#{xml_root}/id").with_text(@group_3.id)
        end

        it 'should return group by name' do
          xget({:filters => {:name => 'Abyssus abyssum invocat'}})

          should have_xpath("#{xml_root}/id").with_text(@group_2.id)
        end

        it 'should not return inactive group by name if that was not specified' do
          xget({:filters => {:name => 'mad'}})

          should == " "
        end

        it 'should return inactive group by name if it is specified' do
          xget({:filters => {:name => 'mad', :inactive => true}})

          should have_xpath("#{xml_root}/id").with_text(@group_3.id)
        end
      end

      it_behaves_like 'entity with include_exclude support' do
        let(:excludes) { %w(steps teams) }
      end
    end

    describe "GET #{base_url}/[id]" do
      let(:url) {"#{base_url}/#{@group_1.id}?token=#{@user.api_key}"}
      before(:each) do
        @role = create(:role)
        @group_1 = create(:group, role_ids: [@role.id])
        @group_2 = create(:group, role_ids: [@role.id])
      end

      context 'JSON' do
        subject { response.body }

        it 'should return group' do
          jget

          should have_json('number.id').with_value(@group_1.id)
        end

        it 'returns all the roles this group belongs to' do
          jget

          response.body.should have_json('array.roles object number.id').
            with_values([@role.id])
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@group_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return group' do
          xget

          should have_xpath("#{xml_root}/id").with_text(@group_2.id)
        end

        it 'returns all the roles this group belongs to' do
          xget

          response.body.should have_xpath('/group/roles/role[1]/id').
            with_text(@role.id)
        end
      end

      it_behaves_like 'entity with include_exclude support' do
        let(:excludes) { %w(steps teams) }
      end
    end

    #***Required Attributes***
    # name - string name of the group (must be unique)
    #***Optional Attributes***
    # active - boolean for active (optional, default true)
    # email - string email of group owner or group mailing list (optional)
    # resource_ids - array of integer ids for related users called "resources" for the group
    # team_ids - array of integer ids for related teams
    describe "POST #{base_url}" do
      let(:url) {"#{base_url}?token=#{token}"}
      let(:team_ids) { [@team.id] }
      let(:resource_ids) { [@resource.id] }
      let(:roles) { [create(:role)] }
      let(:role_ids) { roles.map(&:id) }

      context 'with valid params' do
        let(:param)             { {:name => 'doit',
                                   :active => true,
                                   :email => 'harder@mail.com',
                                   :resource_ids => resource_ids,
                                   :role_ids => role_ids,
                                   :team_ids => team_ids } }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id') }
          it { should have_json('number.position') }
          it { should have_json('array.placeholder_resources') }
          it { should have_json('array.roles object number.id').with_value(role_ids[0]) }

          it 'should have a name' do
            should have_json('string.name').with_value('doit')
          end

          it 'should be active' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should have an email' do
            should have_json('string.email').with_value('harder@mail.com')
          end

          it 'should have resources' do
            should have_json('array.resources number.id').with_values(resource_ids)
          end

          it 'should have teams' do
            should have_json('array.teams number.id').with_values(team_ids)
          end
        end

        context 'XML' do
          before :each do
            @group = create(:group, :name => 'better')
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }
          it { should have_xpath("#{xml_root}/id") }
          it { should have_xpath("#{xml_root}/position") }
          it { should have_xpath("#{xml_root}/placeholder-resources") }
          it { should have_xpath("#{xml_root}/roles/role[1]/id").with_text(role_ids[0]) }

          it 'should have a name' do
            should have_xpath("#{xml_root}/name").with_text('doit')
          end

          it 'should be active' do
            should have_xpath("#{xml_root}/active").with_text('true')
          end

          it 'should have an email' do
            should have_xpath("#{xml_root}/email").with_text('harder@mail.com')
          end

          it 'should have resources' do
            should have_xpath("#{xml_root}/resources/resource/id").with_texts(resource_ids)
          end

          it 'should have teams' do
            should have_xpath("#{xml_root}/teams/team/id").with_texts(team_ids)
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each)  { create(:group, :name => 'already exists') }

        let(:param) { {name: 'already exists'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      let(:url) {"#{base_url}/#{@group.id}?token=#{token}"}
      let(:team_ids) { [@team.id] }
      let(:resource_ids) { [@resource.id] }
      let(:roles) { [create(:role)] }
      let(:role_ids) { roles.map(&:id) }

      context 'with valid params' do
        let(:param) {
          {:name => 'makeit',
           :active => true,
           :email => 'some@mail.com',
           :resource_ids => resource_ids,
           :role_ids => role_ids,
           :team_ids => team_ids }
        }

        context 'JSON' do
          before :each do
            @group = create(:group, :name => 'harder')
            params = {json_root => param}.to_json

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id') }
          it { should have_json('number.position') }
          it { should have_json('array.placeholder_resources') }
          it { should have_json('array.roles object number.id').with_values(role_ids) }

          it 'should have a name' do
            should have_json('string.name').with_value('makeit')
          end

          it 'should be active' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should have an email' do
            should have_json('string.email').with_value('some@mail.com')
          end

          it 'should have resources' do
            should have_json('array.resources number.id').with_values(resource_ids)
          end

          it 'should have teams' do
            should have_json('array.teams number.id').with_values(team_ids)
          end
        end

        context 'XML' do
          before :each do
            @group = create(:group, :name => 'better')
            params = param.to_xml(:root => xml_root)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }
          it { should have_xpath("#{xml_root}/id") }
          it { should have_xpath("#{xml_root}/position") }
          it { should have_xpath("#{xml_root}/placeholder-resources") }
          it { should have_xpath("#{xml_root}/roles/role[1]/id").with_text(role_ids[0]) }

          it 'should have a name' do
            should have_xpath("#{xml_root}/name").with_text('makeit')
          end

          it 'should be active' do
            should have_xpath("#{xml_root}/active").with_text('true')
          end

          it 'should have an email' do
            should have_xpath("#{xml_root}/email").with_text('some@mail.com')
          end

          it 'should have resources' do
            should have_xpath("#{xml_root}/resources/resource/id").with_texts(resource_ids)
          end

          it 'should have teams' do
            should have_xpath("#{xml_root}/teams/team/id").with_texts(team_ids)
          end
        end
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each)  { @group = create(:group) }

        let(:param) { {name: ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @group = create(:group)
        Group.stub(:find).with(@group.id).and_return @group
      end

      let(:url) {"#{base_url}/#{@group.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @group.id }.to_json
          params_xml        = create_xml {|xml| xml.id @group.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          @group.active.should == false
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

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing groups, including a root group' do
    before(:each) { Group.destroy_all }
    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_403, :response_code => 403, mimetypes: mimetypes
  end
end
