require 'spec_helper'

describe DeploymentWindow::SeriesController do

  it_should_behave_like 'status of objects controller', :deployment_window_series, "deployment_window_series"

  before do
    ApplicationController.any_instance.stub(:first_time_login_or_password_reset)
  end

  # This should return the minimal set of attributes required to create a valid
  # DeploymentWindowSeries. As you add validations to DeploymentWindowSeries, be sure to
  # update the return value of this method accordingly.
  let (:valid_attributes) {
      { name: 'test',
        start_at: DateTime.now + 1.day,
        finish_at: DateTime.now + 2.days,
        behavior: 'allow',
        recurrent: false,
        environment_ids: '[]'
      }
    }

  let(:multiparameter_attributes) {
      {
        'start_at' => '08/24/2020',
        'finish_at' => '12/31/2020',
        'start_at(4i)' => '10',
        'start_at(5i)' => '20',
        'finish_at(4i)' => '20',
        'finish_at(5i)' => '10'
      }
    }

  let(:params_for_dws) {
      {
        'start_at(4i)'=>'10',
        'start_at(5i)'=>'20',
        'finish_at(4i)'=>'20',
        'finish_at(5i)'=>'10',
        'start_at(1i)'=>'2020',
        'start_at(2i)'=>'08',
        'start_at(3i)'=>'24',
        'finish_at(1i)'=>'2020',
        'finish_at(2i)'=>'12',
        'finish_at(3i)'=>'31'
      }
    }

  describe "GET index" do
    let(:admin_dws) { create(:deployment_window_series) }
    let(:coordinator_dws) { create(:deployment_window_series) }
    let(:deployer_dws) { create(:recurrent_deployment_window_series) }

    describe "by admin user" do
      before :each do
        @admin = create(:user)
        sign_in @admin
        DeploymentWindow::Series.any_instance.stub_chain(:filter, :search).and_return([admin_dws, coordinator_dws, deployer_dws])
      end

      it "assigns all deployment_window_series as @deployment_window_series " do
        DeploymentWindow::Series.stub(:fetch_depends_on_user).and_return(DeploymentWindow::Series.where('id in (?)', [admin_dws.id, coordinator_dws.id, deployer_dws.id]))
        get :index, {}
        assigns(:deployment_window_series).should eq([admin_dws, coordinator_dws, deployer_dws])
      end

      after :each do
        sign_out @admin
      end
    end

    context 'collection manipulations' do
      let(:test1) { create :deployment_window_series, name: 'test1' }
      let(:test2) { create :deployment_window_series, name: 'test2' }


      it 'searches' do
        get :index, q: '1'
        assigns(:deployment_window_series).should eq [test1]
      end

      it 'orders' do
        get :index, order: { '0' => ['name', 'DESC'] }
        assigns(:deployment_window_series).should eq [test2, test1]
      end

      it 'filters' do
        get :index, act: 'filter', filters: { state: ['state2'] }
        assigns(:deployment_window_series).should eq [test2]
      end
    end
  end

  describe "GET new" do
    it "assigns a new deployment_window_series as @deployment_window_series" do
      get :new
      assigns(:deployment_window_series).should be_a_new(DeploymentWindow::Series)
    end
  end

  describe "GET edit" do
    it "assigns the requested deployment_window_series as @deployment_window_series" do
      deployment_window_series = DeploymentWindow::Series.create! valid_attributes
      # deployment_window_series = DeploymentWindow::Series.new(deployment_window_series)
      get :edit, { id: deployment_window_series.to_param }
      assigns(:deployment_window_series).should eq(deployment_window_series)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new DeploymentWindow::Series" do
        expect {
          post :create, { deployment_window_series: valid_attributes.merge(multiparameter_attributes) }
        }.to change(DeploymentWindow::Series, :count).by(1)
      end

      it "assigns a newly created deployment_window_series as @deployment_window_series" do
        post :create, { deployment_window_series: valid_attributes.merge(multiparameter_attributes) }
        assigns(:deployment_window_series).should be_a(DeploymentWindow::Series)
        assigns(:deployment_window_series).should be_persisted
      end

      it "redirects to the deployment windows list" do
        post :create, { deployment_window_series: valid_attributes.merge(multiparameter_attributes) }
        response.should redirect_to(deployment_window_series_index_url)
      end

      it 'does not call authorize!' do
        expect(controller).to_not receive(:authorize!)

        post :create, deployment_window_series: valid_attributes.merge(multiparameter_attributes)
      end

      it 'sets check_permissions to true' do
        post :create, deployment_window_series: valid_attributes.merge(multiparameter_attributes)

        expect(assigns(:deployment_window_series).check_permissions).to be_truthy
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved deployment_window_series as @deployment_window_series" do
        # Trigger the behavior that occurs when invalid params are submitted
        DeploymentWindow::Series.any_instance.stub(:save).and_return(false)
        post :create, { deployment_window_series: {}}
        assigns(:deployment_window_series).should be_a_new(DeploymentWindow::Series)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        DeploymentWindow::Series.any_instance.stub(:save).and_return(false)
        post :create, { deployment_window_series: {} }
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    let(:deployment_window_series) { create(:deployment_window_series) }
    describe "with valid params" do
      it "updates the requested deployment_window_series" do
        # Assuming there are no other deployment_window_series in the database, this
        # specifies that the DeploymentWindowSeries created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        DeploymentWindow::Series.any_instance.should_receive(:save)
        put :update, { id: deployment_window_series.to_param, deployment_window_series:  valid_attributes.merge(multiparameter_attributes) }
      end

      it "assigns the requested deployment_window_series as @deployment_window_series" do
        DeploymentWindow::SeriesConstruct.any_instance.stub(:update).and_return(true)
        put :update, { id: deployment_window_series.to_param, deployment_window_series: multiparameter_attributes }
        assigns(:deployment_window_series).should eq(deployment_window_series)
      end

      it "redirects to the deployment_window_series" do
        DeploymentWindow::SeriesConstruct.any_instance.stub(:update).and_return(true)
        put :update, { id: deployment_window_series.to_param, deployment_window_series: multiparameter_attributes }
        response.should redirect_to(deployment_window_series_index_url)
      end

      it 'does not call authorize!' do
        expect(controller).to_not receive(:authorize!)

        put :update, id: deployment_window_series.to_param, deployment_window_series: multiparameter_attributes
      end

      it 'sets check_permissions to true' do
        put :update, id: deployment_window_series.to_param, deployment_window_series: multiparameter_attributes

        expect(assigns(:deployment_window_series).check_permissions).to be_truthy
      end
    end

    describe "with invalid params" do
      before :each do
        DeploymentWindow::Series.any_instance.stub(:save).and_return(false)
      end
      it "assigns the deployment_window_series as @deployment_window_series" do
        # Trigger the behavior that occurs when invalid params are submitted
        put :update, { id: deployment_window_series.to_param, deployment_window_series: {} }
        assigns(:deployment_window_series).should eq(deployment_window_series)
      end

      it "re-renders the 'edit' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        put :update, { id: deployment_window_series.to_param, deployment_window_series: {} }
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    let(:series) { create(:deployment_window_series) }
    it "destroys the requested deployment_window_series" do
      series.stub(:archived?).and_return(true)
      DeploymentWindow::Series.any_instance.should_receive(:check_if_destroyable).and_return(true)
      expect {
        delete :destroy, { id: series.to_param }
      }.to change(DeploymentWindow::Series, :count).by(-1)
    end

    it "redirects to the deployment_window_series list" do
      deployment_window_series = DeploymentWindow::Series.create! valid_attributes
      delete :destroy, { id: deployment_window_series.to_param }
      response.should redirect_to(deployment_window_series_index_url)
    end
  end

  context 'private methods' do
    describe '#fetch_deployment_window_series' do
      let(:deployment_window_series) { create(:deployment_window_series) }

      it 'fetch specific records' do
        delete :destroy, { id: deployment_window_series.to_param }
        assigns(:deployment_window_series).should == deployment_window_series
      end
    end
  end
end
