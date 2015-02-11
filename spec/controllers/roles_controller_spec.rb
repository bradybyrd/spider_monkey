require 'spec_helper'

describe RolesController do
  let (:permission_ids) {
    permissions = create_list :permission, 3
    permissions.map(&:id)
  }

  let (:valid_attributes) {
    { name: 'name',
      description: 'description',
      permission_ids: permission_ids
    }
  }

  let(:role) { create :role }

  describe "GET index" do
    before { Role.destroy_all }

    it "assigns all roles as @roles" do
      role1 = create :role
      get :index
      assigns(:roles).should eq([role1])
    end

    context 'collection manipulations' do
      before do
        role1
        role2
      end

      let(:role1) { create :role, name: 'test1' }
      let(:role2) { create :role, name: 'test2' }

      it 'searches' do
        get :index, q: '1'
        expect(assigns(:roles)).to eq [role1]
      end

      it 'orders' do
        get :index, order: { '0' => ['name', 'DESC'] }
        expect(assigns(:roles)).to match_array [role1, role2]
      end
    end
  end

  describe "GET new" do
    it "assigns a new role as @role" do
      get :new
      assigns(:role).should be_a_new(Role)
    end
  end

  describe "GET edit" do
    it "assigns the requested role as @role" do
      get :edit, {:id => role.to_param}
      assigns(:role).should eq(role)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Role" do
        expect {
          post :create, {:role => valid_attributes}
        }.to change(Role, :count).by(1)
      end

      it "assigns a newly created role as @role" do
        post :create, {:role => valid_attributes}
        assigns(:role).should be_a(Role)
        assigns(:role).should be_persisted
      end

      it "redirects to the created role" do
        post :create, {:role => valid_attributes}
        response.should redirect_to(roles_path)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved role as @role" do
        Role.any_instance.stub(:save).and_return(false)
        post :create, {:role => {  }}
        assigns(:role).should be_a_new(Role)
      end

      it "re-renders the 'new' template" do
        Role.any_instance.stub(:save).and_return(false)
        post :create, {:role => {  }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested role" do
        Role.any_instance.should_receive(:update_attributes).with(hash_including({ "name" => "name2" }))
        put :update, {:id => role.to_param, :role => { "name" => "name2" }}
      end

      it "assigns the requested role as @role" do
        put :update, {:id => role.to_param, :role => valid_attributes}
        assigns(:role).should eq(role)
      end

      it "redirects to the role" do
        put :update, {:id => role.to_param, :role => valid_attributes}
        response.should redirect_to(roles_path)
      end
    end

    describe "with invalid params" do
      it "assigns the role as @role" do
        Role.any_instance.stub(:save).and_return(false)
        put :update, {:id => role.to_param, :role => {  }}
        assigns(:role).should eq(role)
      end

      it "re-renders the 'edit' template" do
        Role.any_instance.stub(:save).and_return(false)
        put :update, {:id => role.to_param, :role => {  }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested role" do
      role
      expect {
        delete :destroy, {:id => role.to_param}
      }.to change(Role, :count).by(-1)
    end

    it "redirects to the roles list" do
      delete :destroy, {:id => role.to_param}
      response.should redirect_to(roles_url)
    end
  end

end
