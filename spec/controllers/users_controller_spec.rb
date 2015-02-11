require 'spec_helper'

describe UsersController, type: :controller do
  #### common values
  model = User
  factory_model = :user
  can_archive = false
  #### values for edit
  model_edit_path = '/users'
  edit_flash = nil
  http_refer = nil
  #### values for destroy
  model_delete_path = '/users'

  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  # it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  describe 'DELETE destroy' do
    let!(:destroyable_user) {
      user = create(:user)
      user.deactivate!
      user.user_groups.delete_all
      user
    }

    it 'deletes user' do
      expect { delete :destroy, id: destroyable_user }.to change(User, :count).by(-1)
    end

    it 'redirects to /users' do
      delete :destroy, id: destroyable_user
      response.should redirect_to('/users')
    end
  end

  context '#index' do
    before(:each) do
      User.delete_all
      @users = 31.times.collect { create(:old_user) }
      @users.sort_by! { |el| el.name }
      sign_in @users[0]
    end

    it 'returns active users with pagination and render action' do
      get :index
      @users[0..29].each { |el| assigns(:active_users).should include(el) }
      assigns(:active_users).should_not include(@users[30])
      response.should render_template('index')
    end

    it 'returns active and inactive users with keyword' do
      @active_user = create(:user, last_name: 'Dev1')
      @inactive_user = create(:user, last_name: 'Dev2', active: false)
      get :index, {key: 'Dev'}
      assigns(:active_users).should include(@active_user)
      assigns(:inactive_users).should include(@inactive_user)
      assigns(:active_users).should_not include(@users)
      assigns(:inactive_users).should_not include(@users)
    end

    it "returns flash 'No User'" do
      get :index, {key: 'name'}
      expect(flash[:error]).to eq I18n.t(:'activerecord.notices.not_found', model: 'User')
    end

    it 'renders partial' do
      xhr :get, :index
      response.should render_template(partial: '_list')
    end

    describe 'authorization' do
      before do
        UsersController.any_instance.stub(:can_manage_user?).and_return(true)
      end

      it_behaves_like 'main tabs authorizable', controller_action: :index,
                                                ability_object:    :system_tab
    end
  end

  it '#profile' do
    get :profile
    response.should render_template('profile')
  end

  context '#update_profile' do
    it "returns flash 'success' and redirect to profile path" do
      put :update_profile, {user: {last_name: 'name_changed'}}
      @user.reload
      @user.last_name.should eql('name_changed')
      flash[:success].should include('successfully updated')
      response.should redirect_to(profile_path)
    end

    it 'renders action profile' do
      controller.stub(:current_user).and_return(@user)
      @user.stub(:update_attributes).and_return(false)
      put :update_profile
      response.should render_template('profile')
    end
  end

  it '#deactivate' do
    User.stub(:find).and_return(@user)
    @user.stub(:deactivate).and_return(false)
    put :deactivate, {id: @user.id}
    flash[:error].should_not be_nil
    response.should redirect_to(users_path)
  end

  context '#create' do
    let(:valid_params) { {first_name: 'User_name',
                          last_name: 'User_name'} }

    it 'success' do
      #TODO delete stub and add valid params to request
      User.stub(:new).and_return(@user)
      @user.stub(:save).and_return(true)
      @user.stub(:notification_failed).and_return(false)
      post :create, {user: valid_params, format: 'js'}
      flash[:notice].should include('successfully')
      response.should render_template('misc/redirect')
    end

    it 'shows validation errors' do
      User.stub(:new).and_return(@user)
      @user.stub(:save).and_return(false)
      post :create, {user: {first_name: 'User_name'}}
      response.should render_template('misc/error_messages_for')
    end

    it 'always sets system_user flag' do
      post :create, user: valid_params.merge(system_user: false)
      expect(assigns(:user).system_user).to eq true
    end
  end

  context '#update' do
    let(:valid_params) { {first_name: 'User_name'} }

    it 'success' do
      put :update, {id: @user.id,
                    user: valid_params,
                    format: 'js'}
      flash[:notice].should include('successfully')
      response.should render_template('misc/redirect')
    end

    it 'shows validation errors' do
      User.stub(:find).and_return(@user)
      @user.stub(:update_attributes).and_return(false)
      put :update, {id: @user.id,
                    user: {first_name: 'User_name'}}
      response.should render_template('misc/error_messages_for')
    end

    it 'always sets system_user flag' do
      user = create(:user)
      post :update, id: user.id,
           user: valid_params.merge(system_user: false)
      expect(assigns(:user).system_user).to eq true
    end
  end

  context 'app' do
    before(:each) do
      @app = create(:app)
    end

    it 'associate' do
      @user.remove_direct_access_of_app(@app)
      expect { post :associate_app, {id: @user.id,
                                     app_id: @app.id}
      }.to change(AssignedApp, :count).by(1)
      response.should render_template(partial: 'users/form/_edit_role_by_app_environment')
    end

    it 'disassociate' do
      #@user.set_access_to_app(@app)
      expect { delete :disassociate_app, {id: @user.id,
                                          app_id: @app.id}
      }.to change(AssignedApp, :count).by(-1)
      response.body.should eql('')
    end
  end

  it '#bladelogic' do
    #TODO check last import users
    get :bladelogic
    response.should render_template('bladelogic')
  end

  context '#rbac_import' do
    it 'returns flash success' do
      BladelogicUser.stub(:rbac_import).and_return(2)
      get :rbac_import
      flash[:success].should include('Successfully')
    end

    it 'returns flash error' do
      BladelogicUser.stub(:rbac_import).and_return(nil)
      get :rbac_import
      flash[:error].should include('Error')
    end
  end

  describe 'PUT update_bladelogic_user' do
    it 'finds bladelogic user by id' do
      BladelogicUser.should_receive(:find_by_id)
      put :update_bladelogic_user
    end

    context 'when bladelogic user was not found' do
      it 'renders nothing with status 400' do
        BladelogicUser.stub(:find_by_id).and_return(nil)
        put :update_bladelogic_user
        expect(response.body).to be_blank
        expect(response.status).to eq(400)
      end
    end

    context 'successfull update' do
      let(:user) { double('user', update_attributes: true) }
      it 'renders nothing with status 200' do
        BladelogicUser.stub(:find_by_id).and_return(user)
        put :update_bladelogic_user
        expect(response.body).to be_blank
        expect(response.status).to eq(200)
      end
    end

    context 'update fails' do
      let(:user) { double('user', update_attributes: false) }
      it 'renders nothing with status 400' do
        BladelogicUser.stub(:find_by_id).and_return(user)
        put :update_bladelogic_user
        expect(response.body).to be_blank
        expect(response.status).to eq(400)
      end
    end
  end

  it '#forgot_password' do
    get :forgot_password
    response.should render_template('forgot_password')
  end

  context '#reset_password returns flash' do
    it "'not recognize you'" do
      put :reset_password, {email: '', uid: ''}
      flash[:error].should include('not recognize you')
      response.should render_template(action: 'forgot_password')
    end

    it "'password has been generated' and redirect_to login_path" do
      User.any_instance.stub(:reset_password!).and_return(true)
      put :reset_password, {email: @user.email, uid: @user.login}
      flash[:success].should include('password has been generated')
      response.should redirect_to(login_path)
    end

    it "'could not deliver email'" do
      User.stub(:find_by_email_and_login).and_return(@user)
      @user.stub(:reset_password!).and_return(false)
      put :reset_password, {email: @user.email, uid: @user.login}
      flash[:error].should include('could not deliver email')
    end
  end

  it '#change_password' do
    get :change_password
    response.should render_template('change_password')
  end

  context '#update_password' do
    it 'success' do
      User.any_instance.stub(:change_password!).and_return(true)
      put :update_password, {id: @user.id,
                             user: {password: '123456',
                                    password_confirmation: '123456',
                                    current_password: @user.password},
                             format: 'js'}
      flash[:notice].should include('successfully')
      response.should render_template('misc/redirect')
    end

    it 'fails' do
      User.stub(:find).and_return(@user)
      @user.stub(:change_password!).and_return(false)
      put :update_password, {id: @user.id,
                             user: {password: '123456',
                                    password_confirmation: '123456',
                                    current_password: @user.password}}
      response.should render_template('misc/error_messages_for')
    end
  end

  context '#forgot_userid returns flash' do
    before(:each) do
      @security_answer = SecurityAnswer.new(question_id: '1', answer: 'answer')
      @security_answer.user_id = @user.id
      @security_answer.answer = 'answer'.downcase
      @security_answer.save
    end

    it "'We didn' t recognize You'" do
      User.stub(:find_by_email).and_return(@user)
      @user.stub(:nil?).and_return(true)
      post :forgot_userid, {email: @user.email,
                            answer: ''}
      expect(flash[:error]).to eq I18n.t(:'user.provide_details_for_security_question')
    end

    it "'Your answer does not'" do
      User.stub(:find_by_email).and_return(@user)
      @user.stub(:nil?).and_return(false)
      post :forgot_userid, {email: @user.email,
                            answer: ''}
      flash[:error].should include('')
    end

    it "'Email could not be delivered'" do
      @answer = @user.security_answer
      User.stub(:find_by_email).and_return(@user)
      @user.stub(:nil?).and_return(false)
      @user.stub(:security_answer).and_return(@answer)
      @answer.stub(:eql?).and_return(true)
      post :forgot_userid, {email: @user.email,
                            answer: @user.security_answer.answer}
      expect(flash[:error]).to eq I18n.t(:'user.email_not_delivered')
    end

    it "'Your user ID is e-mailed'" do
      # pending "undefined method `login' for Notifier:Class"
      Notifier.stub_chain(:delay, :login).and_return(true)
      post :forgot_userid, {email: @user.email,
                            answer: 'answer',
                            format: 'js'}
      flash[:success].should include('Your user ID is e-mailed')
      response.should render_template('misc/redirect')
    end
  end

  context '#get_security_question' do
    it 'success' do
      @security_answer = SecurityAnswer.new(question_id: '1', answer: 'answer')
      @security_answer.user_id = @user.id
      @security_answer.answer = 'answer'.downcase
      @security_answer.save
      get :get_security_question, {email: @user.email}
    end

    it 'fails' do
      User.stub(:find_by_email).and_return(@user)
      @user.stub(:nil?).and_return(true)
      get :get_security_question, {email: @user.email,
                                   format: 'js'}
      response.should render_template('misc/update_div.js')
    end
  end

  context '#calendar_preferences' do
    it 'success' do
      post :calendar_preferences, {user: {calendar_preferences: ['status']}}
      @user.reload
      @user.calendar_preferences.should include('status')
      flash[:success].should include('successfully')
      response.should render_template('calendar_preferences')
    end

    it 'fails' do
      User.stub(:find).and_return(@user)
      @user.stub(:update_attribute).and_return(false)
      post :calendar_preferences, {user: {calendar_preferences: ['status']}}
      flash[:success].should include('some problem')
    end
  end

  it '#update_last_response' do
    User.stub_chain(:active, :currently_logged_in, :all).and_return([@user])
    put :update_last_response, {id: @user.id}
    response.should render_template(json: @user)
  end

  context '#request_list_preferences' do

    it 'returns list' do
      get :request_list_preferences, {id: @user.id}
      response.should render_template('request_list_preferences')
    end

    it 'renders partial' do
      @preference = create(:preference, user: @user)
      post :request_list_preferences, {id: @preference.id,
                                       preference: {text: 'text_changed'}}
      @preference.reload
      @preference.text.should eql('text_changed')
      response.should render_template(partial: 'users/preferences/_request_list_row')
    end
  end

  context '#step_list_preferences' do

    it 'returns list' do
      get :step_list_preferences
      response.should render_template('step_list_preferences')
    end

    it 'renders partial' do
      @preference = create(:preference, user: @user)
      post :step_list_preferences, {id: @preference.id,
                                    preference: {text: 'text_changed'}}
      @preference.reload
      @preference.text.should eql('text_changed')
      response.should render_template(partial: 'users/preferences/_step_list_row')
    end

    it 'renders nothing' do
      post :step_list_preferences, {id: '-1',
                                    preference: {text: 'text_changed'}}
      response.should render_template(nothing: true)
    end
  end

  describe 'GET reset_request_preferences' do
    it 'renders users/request_list_preferences template' do
      get :reset_request_preferences
      response.should render_template('users/request_list_preferences')
    end
  end

  it '#reset_step_preferences' do
    get :reset_step_preferences, {id: @user.id}
    response.should render_template('users/step_list_preferences')
  end

  it '#applications' do
    @app = create(:app)
    @assigned_app1 = AssignedApp.create(user_id: @user.id, app_id: @app.id)
    get :applications, {id: @user.id}
    response.body.should include("#{@app.id}")
  end

end
