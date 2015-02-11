require 'spec_helper'
describe 'v1/users', type: :request do
  before :all do
    @root_group = create(:group, root: true)
    @root_user = create(:user, first_name: 'root', groups: [@root_group])
    User.current_user = @root_user
    @root_user.reload
  end

  let(:base_url) { 'v1/users' }
  let(:token) { @root_user.api_key }
  let(:json_root) { :user }
  let(:xml_root) { 'user' }
  let(:params) { {} }

  describe 'GET /v1/users' do
    before(:each) { @user = create(:user) }
    let(:url) { "#{base_url}/?token=#{token}" }

    describe 'filtered by keyword' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { keyword: @user.last_name } } }
        it { response.body.should have_json('string.last_name').with_value(@user.last_name) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { keyword: @user.last_name } } }
        it { response.body.should have_xpath('/users/user/last-name').with_text(@user.last_name) }
      end
    end

    describe 'filtered by email' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { email: @user.email } } }
        it { response.body.should have_json('string.email').with_value(@user.email) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { email: @user.email } } }
        it { response.body.should have_xpath('/users/user/email').with_text(@user.email) }
      end
    end

    describe 'filtered by first_name' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { first_name: @user.first_name } } }
        it { response.body.should have_json('string.first_name').with_value(@user.first_name) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { first_name: @user.first_name } } }
        it { response.body.should have_xpath('/users/user/first-name').with_text(@user.first_name) }
      end
    end

    describe 'filtered by last_name' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { last_name: @user.last_name } } }
        it { response.body.should have_json('string.last_name').with_value(@user.last_name) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { last_name: @user.last_name } } }
        it { response.body.should have_xpath('/users/user/last-name').with_text(@user.last_name) }
      end
    end

    describe 'filtered by active' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { active: true } } }
        it { response.body.should have_json(':root > object > boolean.active').with_value(@user.active) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { active: true } } }
        it { response.body.should have_xpath('/users/user/active').with_text(@user.active) }
      end
    end

    describe 'filtered by inactive' do
      before(:each) do
        @inactive_user = create(:user, active: false)
        @inactive_user.reload
      end
      let(:params) { {filters: {inactive: true}} }

      subject {response.body}

      it 'JSON' do
        @inactive_user.reload
        jget params
        should have_json(':root > object > number.id').with_values([@inactive_user.id])
      end

      it 'XML' do
        @inactive_user.reload
        xget params
        should have_xpath('/users/user/id').with_texts([@inactive_user.id])
      end
    end

    describe 'filtered by first_name, last_name, email' do
      it_behaves_like 'successful request', type: :json do
        let(:params) { { filters: { first_name: @user.first_name, last_name: @user.last_name, email: @user.email } } }

        it { response.body.should have_json('string.first_name').with_value(@user.first_name) }
        it { response.body.should have_json('string.last_name').with_value(@user.last_name) }
        it { response.body.should have_json('string.email').with_value(@user.email) }
      end

      it_behaves_like 'successful request', type: :xml do
        let(:params) { { filters: { first_name: @user.first_name, last_name: @user.last_name, email: @user.email } } }

        it { response.body.should have_xpath('/users/user/first-name').with_text(@user.first_name) }
        it { response.body.should have_xpath('/users/user/last-name').with_text(@user.last_name) }
        it { response.body.should have_xpath('/users/user/email').with_text(@user.email) }
      end
    end

    describe 'non filtered' do
      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json('array:root > object > number.id').with_values(User.pluck(:id)) }
        it { should have_json('string.login').with_values(User.pluck(:login)) }
        it { should have_json('string.first_name').with_values(User.pluck(:first_name)) }
        it { should have_json('string.last_name').with_values(User.pluck(:last_name)) }
        it { should have_json('array:root > object > string.email').with_values(User.pluck(:email)) }
        it { should have_json('string.employment_type').with_values(User.pluck(:employment_type)) }
        it { should have_json(':root > object > boolean.active').with_values(User.pluck(:active)) }
        it { should have_json('boolean.admin').with_values(User.pluck(:admin)) }
        it { should have_json('string.created_at') }
        it { should have_json('string.updated_at') }
      end

      it_behaves_like 'successful request', type: :xml  do
        let(:xml_root) {'/users/user'}
        subject { response.body }
        it { should have_xpath("#{xml_root}/id").with_texts(User.pluck(:id)) }
        it { should have_xpath("#{xml_root}/login").with_texts(User.pluck(:login)) }
        it { should have_xpath("#{xml_root}/first-name").with_texts(User.pluck(:first_name)) }
        it { should have_xpath("#{xml_root}/last-name").with_texts(User.pluck(:last_name)) }
        it { should have_xpath("#{xml_root}/email").with_texts(User.pluck(:email)) }
        it { should have_xpath("#{xml_root}/employment-type").with_texts(User.pluck(:employment_type)) }
        it { should have_xpath("#{xml_root}/active").with_texts(User.pluck(:active)) }
        it { should have_xpath("#{xml_root}/admin").with_texts(User.pluck(:admin)) }
        it { should have_xpath("#{xml_root}/created-at") }
        it { should have_xpath("#{xml_root}/updated-at") }
      end
    end
  end

  describe 'GET /v1/users/[id]' do
    before(:each) { @user = create(:user) }
    let(:url) { "#{base_url}/#{@user.id}/?token=#{token}" }

    it_behaves_like 'successful request', type: :json  do
      subject { response.body }
      it { should have_json(':root > number.id').with_value(@user.id) }
      it { should have_json('string.login').with_value(@user.login) }
      it { should have_json('string.first_name').with_value(@user.first_name) }
      it { should have_json('string.last_name').with_value(@user.last_name) }
      it { should have_json('string.email').with_value(@user.email) }
      it { should have_json('string.employment_type').with_value(@user.employment_type) }
      it { should have_json(':root > boolean.active').with_value(@user.active) }
      it { should have_json('boolean.admin').with_value(@user.admin) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like 'successful request', type: :xml  do
      subject { response.body }
      it { should have_xpath('/user/id').with_text(@user.id) }
      it { should have_xpath('/user/login').with_text(@user.login) }
      it { should have_xpath('/user/first-name').with_text(@user.first_name) }
      it { should have_xpath('/user/last-name').with_text(@user.last_name) }
      it { should have_xpath('/user/email').with_text(@user.email) }
      it { should have_xpath('/user/employment-type').with_text(@user.employment_type) }
      it { should have_xpath('/user/active').with_text(@user.active) }
      it { should have_xpath('/user/admin').with_text(@user.admin) }
      it { should have_xpath('/user/created-at') }
      it { should have_xpath('/user/updated-at') }
    end
  end

  describe 'POST /v1/users' do
    let(:url) { "#{base_url}/?token=#{token}" }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do

      let(:login) { 'login_json' }
      let(:first_name) { 'Jane_json' }
      let(:last_name) { 'Smith_json' }
      let(:email) { "#{first_name}_#{last_name}@example.com" }
      let(:password) { 'testtest1' }
      let(:password_confirmation) { password }
      let(:groups) { [create(:group, name: 'foo')] }
      let(:group_ids) { groups.map(&:id) }
      let(:params) { { json_root => { first_name: first_name,
                                      last_name: last_name,
                                      login: login,
                                      email: email,
                                      password: password,
                                      password_confirmation: password_confirmation,
                                      group_ids: group_ids } }.to_json }
      let(:added_user) { User.last }

      subject { response.body }
      it { should have_json(':root > number.id').with_value(added_user.id) }
      it { should have_json('string.login').with_value(added_user.login) }
      it { should have_json('string.first_name').with_value(added_user.first_name) }
      it { should have_json('string.last_name').with_value(added_user.last_name) }
      it { should have_json('string.email').with_value(added_user.email) }
      it { should have_json('array.groups object number.id').with_value(added_user.group_ids[0]) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
      it { should have_json('boolean.active').with_value(true) }
    end

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do

      let(:login) { 'login_xml' }
      let(:first_name) { 'Jane_xml' }
      let(:last_name) { 'Smith_xml' }
      let(:email) { "#{first_name}_#{last_name}@example.com" }
      let(:password) { 'testtest1' }
      let(:password_confirmation) { password }
      let(:groups) { [create(:group, name: 'foo')] }
      let(:group_ids) { groups.map(&:id) }
      let(:params) { { first_name: first_name,
                       last_name: last_name,
                       login: login,
                       email: email,
                       password: password,
                       password_confirmation: password_confirmation,
                       group_ids: group_ids  }.to_xml(root: xml_root) }
      let(:added_user) { User.last }

      subject { response.body }
      it { should have_xpath('/user/id').with_text(added_user.id) }
      it { should have_xpath('/user/login').with_text(added_user.login) }
      it { should have_xpath('/user/first-name').with_text(added_user.first_name) }
      it { should have_xpath('/user/last-name').with_text(added_user.last_name) }
      it { should have_xpath('/user/email').with_text(added_user.email) }
      it { should have_xpath('/user/groups/group[1]/id').with_text(added_user.group_ids[0]) }
      it { should have_xpath('/user/created-at') }
      it { should have_xpath('/user/updated-at') }
      it { should have_xpath('/user/active').with_text('true') }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {first_name: nil, last_name: nil, password: nil, login: nil, email: nil} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/users/[id]' do
    before(:each) { @user = create(:user) }

    let(:url) { "#{base_url}/#{@user.id}/?token=#{token}" }

    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:new_login) { 'login_json_new' }
      let(:new_first_name) { 'Jane_json_new' }
      let(:new_last_name) { 'Smith_json_new' }
      let(:new_email) { "#{new_first_name}_#{new_last_name}@example.com" }
      let(:new_password) { 'testtest_json' }
      let(:new_password_confirmation) { new_password }
      let(:new_groups) { [create(:group, name: 'bar')] }
      let(:new_group_ids) { new_groups.map(&:id) }
      let(:params) { {json_root => { first_name: new_first_name,
                                     last_name: new_last_name,
                                     login: new_login,
                                     email: new_email,
                                     password: new_password,
                                     password_confirmation: new_password_confirmation,
                                     group_ids: new_group_ids } }.to_json}
      let(:updated_user) { User.last }

      subject { response.body }
      it { should have_json(':root > number.id').with_value(updated_user.id) }
      it { should have_json('string.login').with_value(updated_user.login) }
      it { should have_json('string.first_name').with_value(updated_user.first_name) }
      it { should have_json('string.last_name').with_value(updated_user.last_name) }
      it { should have_json('string.email').with_value(updated_user.email) }
      it { should have_json('array.groups object number.id').with_value(updated_user.group_ids[0]) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:new_login) { 'login_xml_new' }
      let(:new_first_name) { 'Jane_xml_new' }
      let(:new_last_name) { 'Smith_xml_new' }
      let(:new_email) { "#{new_first_name}_#{new_last_name}@example.com" }
      let(:new_password) { 'testtest1_xml' }
      let(:new_password_confirmation) { new_password }
      let(:new_groups) { [create(:group, name: 'bar')] }
      let(:new_group_ids) { new_groups.map(&:id) }
      let(:params) { { first_name: new_first_name,
                       last_name: new_last_name,
                       login: new_login,
                       email: new_email,
                       password: new_password,
                       password_confirmation: new_password_confirmation,
                       group_ids: new_group_ids }.to_xml(root: xml_root) }
      let(:updated_user) { User.last }

      subject { response.body }
      it { should have_xpath('/user/id').with_text(updated_user.id) }
      it { should have_xpath('/user/login').with_text(updated_user.login) }
      it { should have_xpath('/user/first-name').with_text(updated_user.first_name) }
      it { should have_xpath('/user/last-name').with_text(updated_user.last_name) }
      it { should have_xpath('/user/email').with_text(updated_user.email) }
      it { should have_xpath('/user/groups/group[1]/id').with_text(updated_user.groups[0].id) }
      it { should have_xpath('/user/created-at') }
      it { should have_xpath('/user/updated-at') }
    end

    it_behaves_like 'change `active` param'

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {first_name: nil, last_name: nil, password: nil, login: nil, email: nil} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'DELETE /v1/users/[id]' do
    types = %w(json xml)

    types.each do |type|
      before(:each) do
        @user_for_delete = create(:user)
      end

      let(:url) { "#{base_url}/#{@user_for_delete.id}/?token=#{token}" }
      it_behaves_like 'successful request', type: type, method: :delete, status: 202 do
        let(:params) {{}}
        it { User.find(@user_for_delete.id).active.should be_falsey }
      end
    end
  end
end

# helpers
def delete_all_users_except_root
  User.where("first_name not like 'root'").delete_all
end
alias :delete_users :delete_all_users_except_root
