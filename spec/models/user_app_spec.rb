################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe UserApp do
  before(:each) do
    @user = create(:user)
    User.current_user = @user
    @user1 = create(:user, login: 'rspecuser')
    @app1 = create(:app)
    @app2 = create(:app)
    @user_app1 = UserApp.new
  end

  describe 'associations and validations' do
    it 'should validate presence' do
      @user_app1.should validate_presence_of(:user_id)
      @user_app1.should validate_presence_of(:app_id)
    end

    it 'should belong to' do
      @user_app1.should belong_to(:user)
      @user_app1.should belong_to(:app)
    end
  end

  describe 'named scopes' do
    it 'of_user' do
      @user_app2 = create(:user_app, user: @user1, app: @app2)
      @user_app3 = create(:user_app, user: @user1, app: @app1)

      @user_app4 = create(:user_app, user: @user, app: @app2)

      UserApp.of_user(@user1.id).count.should == 2
      UserApp.of_user(@user.id).count.should == 1

    end

    it 'visible' do
      @user_app2 = create(:user_app, user: @user1, app: @app2, visible: true)
      @user_app3 = create(:user_app, user: @user1, app: @app1, visible: true)

      @user_app4 = create(:user_app, user: @user, app: @app2, visible: false)

      UserApp.visible.should include(@user_app2)
      UserApp.visible.should include(@user_app3)
    end

  end

end

