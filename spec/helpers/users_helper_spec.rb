require 'spec_helper'

describe UsersHelper do
  before(:each) { @user = create(:old_user) }

  describe '#class_for_role_radio_button' do
    it 'returns spinner' do
      helper.class_for_role_radio_button.should eql('spinner user_default_roles')
    end

    it 'returns nothing' do
      @user.stub(:new_record?).and_return(true)
      helper.class_for_role_radio_button.should eql('')
    end
  end

  describe '#welcome_with_name' do
    before(:each) { helper.stub(:current_user).and_return(@user) }

    it 'returns label' do
      @user.stub(:first_time_login?).and_return(true)
      helper.welcome_with_name.should eql("Welcome #{@user.first_name} #{@user.last_name}")
    end

    it 'returns Back' do
      helper.welcome_with_name.should eql("Welcome Back, #{@user.name}")
    end
  end

  describe '#password_changable?' do
    before(:each) do
      @current_user = create(:old_user)
      helper.stub(:current_user).and_return(@current_user)
    end

    context 'default authentication enabled and current user authenticated via rpm' do
      before(:each) do
        helper.stub(:current_user_authenticated_via_rpm?).and_return true
        GlobalSettings.stub(:default_authentication_enabled?).and_return true
      end

      it 'success result for new_record' do
        @user.stub(:new_record?).and_return(true)
        helper.should_receive(:can?).with(:create, @user).and_return true
        helper.password_changable?(@user, @current_user).should be_truthy
      end

      it 'success result for created_record' do
        @user.stub(:new_record?).and_return(false)
        helper.should_receive(:can?).with(:edit, @user).and_return true
        helper.password_changable?(@user, @current_user).should be_truthy
      end

      it 'failure result for new_record' do
        @user.stub(:new_record?).and_return(true)
        helper.should_receive(:can?).with(:create, @user).and_return false
        helper.password_changable?(@user, @current_user).should be_falsey
      end

      it 'failure result for created_record' do
        @user.stub(:new_record?).and_return(false)
        helper.should_receive(:can?).with(:edit, @user).and_return false
        helper.password_changable?(@user, @current_user).should be_falsey
      end

      it 'success result for self user' do
        @user.stub(:new_record?).and_return(false)
        helper.stub(:can?).with(:edit, @user).and_return false
        helper.password_changable?(@user, @user).should be_truthy
      end

    end

    it 'default authentication disabled' do
      helper.stub(:current_user_authenticated_via_rpm?).and_return true
      GlobalSettings.stub(:default_authentication_enabled?). and_return false
      helper.password_changable?(@user, @current_user).should be_falsey
    end

    it 'current user not authenticated via rpm' do
      helper.stub(:current_user_authenticated_via_rpm?).and_return false
      GlobalSettings.stub(:default_authentication_enabled?). and_return true
      helper.password_changable?(@user, @current_user).should be_falsey
    end

  end
end