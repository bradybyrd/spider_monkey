require "spec_helper"
describe V1::RolesController, type: :request do
  before :all do
    @root_group = create(:group, root: true)
    @root_user = create(:user, first_name: 'root', groups: [@root_group])
    User.current_user = @root_user
    @root_user.reload
  end

  let(:base_url) { "/v1/roles" }
  let(:token) { @root_user.api_key }
  let(:json_root) { :role }
  let(:xml_root) { 'role' }
  let(:params) { {} }

  def role_url(role, type)
    "#{base_url}/#{role.id}.#{type}?token=#{token}"
  end

  describe "GET /v1/roles" do
    let(:url) { "#{base_url}?token=#{token}" }
    let(:roles) { Role.all }

    describe "filtered by name" do
      it_behaves_like "successful request", type: :json do
        let(:params) { { filters: { name: roles.first.name } } }
        it { response.body.should have_json('string.name').with_value(roles.first.name) }
      end

      it_behaves_like "successful request", type: :xml do
        let(:params) { { filters: { name: roles.first.name } } }
        it { response.body.should have_xpath('/roles/role/name').with_text(roles.first.name) }
      end
    end

    describe "filtered by active" do
      it_behaves_like "successful request", type: :json do
        let(:params) { { filters: { active: true } } }
        it { response.body.should have_json('boolean.active').with_value(true) }
      end

      it_behaves_like "successful request", type: :xml do
        let(:params) { { filters: { active: true } } }
        it { response.body.should have_xpath('/roles/role/active').with_text(true) }
      end
    end

    describe "non filtered" do
      it_behaves_like "successful request", type: :json do
        subject { response.body }
        it { should have_json('number.id').with_values(Role.pluck(:id)) }
        it { should have_json('string.name').with_values(Role.pluck(:name)) }
        it { should have_json('boolean.active').with_values(Role.pluck(:active)) }
      end

      it_behaves_like "successful request", type: :xml  do
        subject { response.body }
        it { should have_xpath("/roles/role/id").with_texts(Role.pluck(:id)) }
        it { should have_xpath("/roles/role/name").with_texts(Role.pluck(:name)) }
        it { should have_xpath("/roles/role/active").with_texts(Role.pluck(:active)) }
      end
    end
  end

  describe "GET /v1/roles/[id]" do
    context "when an active role exists" do
      it "returns the Role in XML format" do
        role = create(:role, active: true, name: "good role")
        url = "#{base_url}/#{role.id}.xml?token=#{token}"

        get role_url(role, "xml")

        expect(response.body).to have_role_element("id").with_text(role.id)
        expect(response.body).to have_role_element("name").with_text("good role")
        expect(response.body).to have_role_element("active").with_text(true)
      end

      it "returns the Role in JSON format" do
        role = create(:role, active: true, name: "good role")
        url = "#{base_url}/#{role.id}.json?token=#{token}"

        get role_url(role, "json")

        expect(response.body).to have_role_key("number.id").with_value(role.id)
        expect(response.body).to have_role_key("string.name").with_value("good role")
        expect(response.body).to have_role_key("boolean.active").with_value(true)
      end

      def have_role_element(name)
        have_xpath("/role/#{name}")
      end

      def have_role_key(name)
        have_json(name)
      end
    end

    context "when an active role does not exist" do
      it "return a 404" do
        role = create(:role, active: false)

        get role_url(role, "json")

        expect(response.status).to eq 404
      end
    end
  end

  describe "DELETE /v1/roles/[id]" do
    ['json', 'xml'].each do |type|
      let(:role_for_delete) { create(:role) }
      let(:url) { "#{base_url}/#{role_for_delete.id}?token=#{token}" }
      it_behaves_like "successful request", type: type, method: :delete, status: 202 do
        let(:params) { {} }
        it { Role.find(role_for_delete.id).active.should be_falsy }
      end

      context "when a Role is on a Group" do
        it "does not deactivate the Role" do
          role_for_delete.groups << create(:group)

          delete role_url(role_for_delete, type)

          role_for_delete.reload
          expect(role_for_delete).to be_active
        end

        it "responds with Precondition Failed" do
          role_for_delete.groups << create(:group)

          delete role_url(role_for_delete, type)

          expect(response.status).to eq 412
        end
      end

      context "when a Role is not on a Group" do
        it "deactivates the Role" do
          role_for_delete.groups.clear

          delete role_url(role_for_delete, type)

          role_for_delete.reload
          expect(role_for_delete).to_not be_active
        end

        it "responds with Accepted" do
          role_for_delete.groups.clear

          delete role_url(role_for_delete, type)

          expect(response.status).to eq 202
        end
      end
    end
  end
end
