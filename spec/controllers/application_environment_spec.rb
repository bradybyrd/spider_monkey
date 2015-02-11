require 'spec_helper'

describe ApplicationEnvironmentsController, :type => :controller do
  before (:each) do
    @app = create(:app)
    @env = create(:environment)
    @app_environment = create(:application_environment, :app => @app, :environment => @env)
  end

  context 'authorization' do
    context 'authorize fails' do
      describe '#add_remove' do
        include_context 'mocked abilities', :cannot, :add_remove, ApplicationEnvironment

        it 'redirects to root path' do
          get :add_remove, app_id: @app.id
          expect(response).to redirect_to root_path
        end
      end

      describe '#update_all' do
        context 'for existing environment' do
          include_context 'mocked abilities', :cannot, :add_remove, ApplicationEnvironment

          it 'redirects to root path' do
            put :update_all, app_id: @app.id
            expect(response).to redirect_to root_path
          end
        end

        context 'for new environment' do
          include_context 'mocked abilities', :cannot, :create, Environment

          it 'does not create new environment' do
            expect {
              put :update_all, { app_id: @app.id,
                                 environment_ids: [@env.id],
                                 new_environments: [{ name: "Env_new1" }] }
            }.to change(@app.application_environments, :count).by(0)
          end
        end
      end
    end
  end

  it "#index" do
    get :index, :app_id => @app.id
    response.should render_template("apps/_default_environment")
  end

  it "#add_remove" do
    get :add_remove, :app_id => @app.id
    response.should render_template(:partial => 'application_environments/_add_remove')
  end

  it "#update" do
    put :update, {:app_id => @app.id,
                  :id => @app_environment.id,
                  :environment => {:position => 2}}
    @app_environment.reload
    @app_environment.position.should eql(2)
    response.should render_template(:partial => '_for_reorder')
  end

  context "#update_all" do
    it "create new environment" do
      expect{put :update_all, {:app_id => @app.id,
                               :id => @app_environment.id,
                               :environment_ids => [@env.id],
                               :new_environments => [{:name => "Env_new1"}]}
            }.to change(@app.application_environments, :count).by(1)
      response.should render_template(:partial => "apps/_default_environment")
    end

    it "change environment ids" do
      put :update_all, {:app_id => @app.id,
                        :id => @app_environment.id,
                        :environment_ids => [@env.id]}
      response.should render_template(:partial => "apps/_default_environment")
    end

    it 'clears permissions cache', custom_roles: true do
      expect(PermissionMap.instance).to receive(:clean)
      put :update_all, app_id: @app.id, environment_ids: [@env.id]
    end
  end

  it "#edit" do
    get :edit, {:app_id => @app.id,
                :id => @app_environment.id}
    response.should render_template(:partial => 'apps/_application_environment_edit_row')
  end

  it "#show" do
    get :show, {:app_id => @app.id,
                :id => @app_environment.id}
    response.should render_template(:partial => 'apps/_application_environment_show_row')
  end
end
