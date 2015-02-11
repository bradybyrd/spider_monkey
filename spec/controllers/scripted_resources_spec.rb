require 'spec_helper'

describe ScriptedResourcesController, :type => :controller do
  before(:each) { @script = create(:general_script) }

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { get :new }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { post :create }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { get :edit, id: @script }
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { put :update, id: @script }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, :automation
        specify { delete :destroy, id: @script }
      end
    end
  end

  context "#edit" do
    it "returns error 'does not exist'" do
      get :edit, {:id => '-1'}
      flash[:error].should include('does not exist')
      response.should redirect_to(automation_scripts_path)
    end

    it "renders template edit" do
      xhr :get, :edit, {:id => @script.id}
      response.should render_template('scripted_resources/edit')
    end

    it "renders template detail_edit" do
      get :edit, {:id => @script.id}
      response.should render_template('scripted_resources/detail_edit')
    end
  end

  context "#update" do
    context "success" do
      it "renders template update" do
        xhr :put, :update, {:id => @script.id,
                            :script => {:name => 'Changed'}}
        @script.reload
        @script.name.should eql('Changed')
        response.should render_template("shared_scripts/update")
      end

      it "redirects to index" do
        put :update, {:id => @script.id,
                       :script => {:name => 'Changed'}}
        response.should redirect_to('/environment/scripted_resources')
      end
    end

    context "fails" do
      before(:each) do
        Script.stub(:find).and_return(@script)
        @script.stub(:update_attributes).and_return(false)
      end

      it "shows validation errors" do
        xhr :put, :update, {:id => @script.id,
                            :script => {:name => 'Changed'}}
        response.should render_template('misc/error_messages_for')
      end

      it "renders template edit" do
        put :update, {:id => @script.id,
                      :script => {:name => 'Changed'}}
        response.should render_template('scripted_resources/detail_edit')
      end
    end
  end

  context "#create" do
    before(:each) do
      @params = {:script => {:name => "script name2",
                             :content => 'script_content',
                             :automation_category => 'General',
                             :unique_identifier => "AutomationId2"}}
    end

    context "success" do
      it "redirects by ajax" do
        @params[:script][:unique_identifier] = "AutomationId1"
        expect{xhr :post, :create, @params
              }.to change(Script, :count).by(1)
        response.should render_template('misc/redirect')
      end

      it "redirects to automation scripts path" do
        post :create, @params
        response.should redirect_to(automation_scripts_path)
      end
    end

    context "fails" do
      before(:each) do
        Script.delete_all
        @scripts = create_list(:general_script, 4)
        Script.stub(:new).and_return(@script)
        @script.stub(:save).and_return(false)
      end

      it "returns paginated records and show validation errors" do
        xhr :post, :create, @params.merge(per_page: 3)
        @scripts[0..2].each { |el| assigns(:scripts).should include(el) }
        assigns(:scripts).should_not include(@scripts[3])
        response.should render_template('misc/error_messages_for')
      end

      it "renders template new" do
        post :create, @params
        response.should render_template('scripted_resources/detail_new')
      end
    end
  end
end
