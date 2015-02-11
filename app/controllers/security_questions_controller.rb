################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class SecurityQuestionsController < ApplicationController
  skip_before_filter :verify_user_login_status
  before_filter :find_user

  def new
    @user.build_security_answer
  end

  def create # TODO - Add security_question with user object
    if current_user_authenticated_via_rpm?
      @user.password = params[:user][:password].empty? ? @user.encrypted_password : params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      @user.current_password = params[:user][:current_password]
    end
    if params[:user][:email]
      @user.email = params[:user][:email]
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
    end
    user = @user.valid?
    if current_user_authenticated_via_rpm?
      @security_answer = SecurityAnswer.new(params[:user][:security_answer])
      security_answer = @security_answer.valid?
    else
      security_answer = true
    end
    if user && security_answer
      @user.first_time_login = false
      @user.is_reset_password = false
      @user.save
      if @security_answer
        @security_answer.user_id = @user.id
        @security_answer.answer = params[:user][:security_answer][:answer].downcase
        @security_answer.save
      end
      ajax_redirect(my_dashboard_path)
    else
      respond_to do |format|
        @div = 'errors'
        if @security_answer
          @div_content = render_to_string(:template => 'misc/error_messages_for', :layout => false, :locals => {:item => @user, :item2 => @security_answer})
        else
          @div_content =  render_to_string(:template => 'misc/error_messages_for', :layout => false, :locals => {:item => @user})
        end
        format.js { render :template => 'misc/update_div.js.erb', :content_type => 'application/javascript'}
      end
    end
  end

  private

  def find_user
    @user = User.find(current_user)
  end
end
