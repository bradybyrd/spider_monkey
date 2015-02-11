require 'spec_helper'

describe SessionsController, type: :controller do
  before(:each) do
    GlobalSettings.instance.destroy
    GlobalSettings.clear_local_instance
  end

  context '#new' do
    context 'cas_authentication' do
      before(:each) do
        GlobalSettings.stub(:cas_enabled?).and_return(true)
        sign_out @user
      end

      it 'redirects to cas_login_url' do
        session[:cas_user] = nil
        CASClient::Frameworks::Rails::Filter.stub(:login_url).and_return(login_url(@user))
        get :new, {brpmadmin: 'false'}
        expect(response).to redirect_to(login_url(@user))
      end

      it "renders action and returns flash 'Restart Your server'" do
        session[:cas_url].stub(:blank?).and_return(true)
        get :new, {brpmadmin: 'false'}
        expect(flash.now[:error]).to include('Restart Your server')
        expect(response).to render_template('new')
      end

      it "returns error 'account login is disabled'" do
        session[:cas_user] = @user
        User.stub(:find_by_login).and_return(@user)
        @user.stub(:blank?).and_return(false)
        @user.stub(:active?).and_return(false)
        get :new, {brpmadmin: 'false'}
        expect(flash[:error]).to include('account login is disabled')
        expect(response).to redirect_to(login_path)
      end

      it 'signs in with cas user and redirect' do
        session[:cas_user] = @user
        User.stub(:find_by_login).and_return(@user)
        @user.stub(:blank?).and_return(true)
        User.stub(:cas_authentication).and_return(@user)
        get :new, {brpmadmin: 'false'}
        expect(response).to render_template(@user)
      end

      it 'redirects to new security question path' do
        controller.stub(:valid_attr_for?).and_return(false)
        session[:cas_user] = @user
        User.stub(:find_by_login).and_return(@user)
        @user.stub(:blank?).and_return(false)
        @user.stub(:active?).and_return(true)
        get :new, {brpmadmin: 'false'}
        expect(response).to redirect_to(new_security_question_path)
      end

      it 'signs in with active cas user and redirect' do
        controller.stub(:valid_attr_for?).and_return(true)
        session[:cas_user] = @user
        User.stub(:find_by_login).and_return(@user)
        @user.stub(:blank?).and_return(false)
        @user.stub(:active?).and_return(true)
        get :new, {brpmadmin: 'false'}
        expect(assigns(:cas_user).first_time_login).to eql(false)
        expect(response).to render_template(@user)
      end
    end

    context 'sso_authentication' do
      before(:each) do
        GlobalSettings.stub(:cas_enabled?).and_return(false)
        sign_out @user
      end

      it 'success' do
        @request.env['REMOTE_USER'] = @user.login
        get :new, {User: {'login' => @user.login,
                          'password' => @user.password}}
        expect(session[:sso_enabled]).to eql(true)
        expect(response).to render_template(@user)
      end

      it 'redirects to new security question path' do
        controller.stub(:valid_attr_for?).and_return(false)
        @request.env['REMOTE_USER'] = @user.login
        get :new
        expect(session[:sso_enabled]).to eql(true)
        expect(response).to redirect_to(new_security_question_path)
      end

      it "returns error 'account is disabled'" do
        User.stub(:sso_authentication).and_return(@user)
        @user.stub(:active?).and_return(false)
        @request.env['REMOTE_USER'] = @user.login
        get :new
        expect(flash[:error]).to include('account login is disabled')
        expect(response).to redirect_to(login_path)
      end

      it 'redirects to root path' do
        sign_in @user
        get :new
        expect(session[:auth_method]).to eql('Login')
        expect(response).to redirect_to(root_path)
      end

      it 'renders action new' do
        get :new
        expect(session[:auth_method]).to eql('Login')
        expect(response).to render_template('new')
      end
    end
  end

  describe '#create' do
    it "returns error 'Only Administrator can login' for non root user trying to sign in via CAS'" do
      GlobalSettings.stub(:cas_enabled?).and_return(true)
      user = create(:user, :non_root)

      post :create, {User: {'login' => user.login}}

      expect(flash[:error]).to include('Only Administrator can login')
      expect(response).to redirect_to(login_path)
    end

    it "returns error 'access to system is blocked' for non active user signing in via LDAP" do
      user = create(:user, :non_root, active: false)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)
      User.stub(:ldap_authentication).and_return(user)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
      }

      expect(flash[:error]).to include('access to the system is blocked')
    end

    it 'signs in the active user successfully via LDAP' do
      user = create(:user, :non_root)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)
      User.stub(:ldap_authentication).and_return(user)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
      }

      expect(flash[:success]).to include('successfully')
    end

    it 'does not sign-in active user with password from DB (with LDAP)' do
      user = create(:user, :non_root)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)
      User.stub(:ldap_authentication).and_return(nil)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
                  }

      expect(flash[:error]).to include('Please re-enter your login')
      expect(response).to redirect_to(login_path)

      get :new
      expect(response).to render_template('new')
      expect(response).to_not redirect_to(root_path)
    end

    it 'signs in user that has never logged in before successfully via LDAP' do
      user = create(:user, :non_root, first_time_login: true)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)
      User.stub(:ldap_authentication).and_return(user)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
      }

      expect(response).to redirect_to(root_path)
    end

    it "returns flash 'A new account has been created'" do
      user = create(:user, :non_root, first_time_login: true)
      controller.stub(:valid_attr_for?).and_return(false)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)
      User.stub(:ldap_authentication).and_return(user)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
      }

      expect(response).to redirect_to(new_security_question_path)
    end

    it "returns error 'Please re-enter you login'" do
      user = create(:user, :root)
      GlobalSettings.stub(:ldap_enabled?).and_return(true)

      post :create, {User: {'login' => user.login,
                            'password' => user.password}
      }

      expect(flash[:error]).to include('Please re-enter your login')
      expect(response).to redirect_to(login_path)
    end

    context 'no tabs are selected' do
      before { MainTabs.stub(:selected_any?).and_return(false) }

      it 'sets flash message' do
        post :create, {User: {'login' => @user.login,
                              'password' => @user.password}}
        expect(flash[:notice]).to include('You do not have access permissions to view any tab')
      end
    end
  end

  context '#destroy' do
    it 'SSO success' do
      session[:sso_enabled] = true
      delete :destroy
      expect(flash.now[:success]).to include('logged out')
      expect(response).to render_template('new')
    end

    it "returns error 'restart your server'" do
      session[:sso_enabled] = false
      session[:logged_in_through_cas] = 'true'
      session[:auth_method] = 'CAS'
      GlobalSettings.stub(:cas_enabled?).and_return(true)
      delete :destroy
      expect(flash.now[:error]).to include('Restart Your server')
    end

    it 'CAS success' do
      GlobalSettings.stub(:cas_enabled?).and_return(true)
      delete :destroy
      expect(flash.now[:success]).to include('logged out')
      expect(response).to render_template('new')
    end

    it 'should clean PermissionMap for current_user' do
      PermissionMap.instance.should_receive(:clean).with(@controller.current_user)
      delete :destroy
    end

  end

  it '#bad_route' do
    visit '/bad_route'
    expect(response).to render_template(file: '#{Rails.root}/public/404.html')
  end
end
