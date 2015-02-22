################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'calendar/base'

class UsersController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator
  include MultiplePicker

  skip_before_filter :authenticate_user!, only: [:forgot_password, :reset_password, :forgot_userid,
                                                 :get_security_question]
  skip_before_filter :verify_user_login_status, only: [:forgot_password, :reset_password, :forgot_userid,
                                                                 :get_security_question, :change_password,
                                                                 :update_password]
  skip_before_filter :verify_authenticity_token, if: Proc.new { |c| c.request.format == 'application/json' }
  before_filter :forgot_password_enabled, only: :forgot_password

  before_filter :find_user, :find_app, only: [:associate_app, :disassociate_app]
  before_filter :parse_group_ids, only: [:update, :create]

  cache_sweeper :user_root_sweeper, only: [:update, :destroy]

  def index
    authorize! :view, :system_tab
    @per_page = 30
    @keyword = params[:key]
    @active_users = User.active.not_placeholder.by_last_name
    @inactive_users = User.inactive.not_placeholder.by_last_name
    if @keyword.present?
      @active_users = @active_users.search_user(@keyword.downcase)
      @inactive_users = @inactive_users.search_user(@keyword.downcase)
    end
    @total_records = @active_users.length
    if @active_users.blank? and @inactive_users.blank?
      flash.now[:error] = I18n.t(:'activerecord.notices.not_found', model: 'User')
    end
    @active_users = alphabetical_paginator @per_page, @active_users
    render partial: 'list', locals: { active: true, users: @active_users }, layout: false if request.xhr?
  end

  def profile
    @user = current_user
    @default_tab = @user.default_tab
  end

  def update_profile
    @user = current_user

    if @user.update_attributes params[:user]
      DefaultTab.my_default_tab(@user, params[:tab_name])
      flash[:success] = I18n.t(:'user.profile_updated')
      redirect_to profile_path
    else
      render action: 'profile'
    end
  end

  def deactivate
    user_model = find_user
    authorize! :make_active_inactive, user_model
    unless user_model.deactivate!
      flash[:error] = user_model.errors.full_messages[0]
    end
    redirect_to action: :index, page: params[:page], key: params[:key]
  end

  def new
    @user = User.new
    @groups = Group.all(order: 'name')
    authorize! :create, @user
  end

  def create
    @user = User.new params[:user].merge(system_user: true)
    authorize! :create, @user

    if @user.save
      flash[:notice] = I18n.t(:'user.created', user_name: @user.name_for_index)
      ajax_redirect(users_path(page: params[:page], key: params[:key]))
    else
      show_validation_errors(:user)
    end
  end

  def edit
    @user = find_user
    authorize! :edit, @user

    @groups = Group.all(order: 'name')
  end

  def update
    @user = find_user
    authorize! :edit, @user

    if @user.update_attributes params[:user].merge(system_user: true)
      #PermissionMap.instance.clean(@user)
      flash[:notice] = I18n.t(:'user.updated', user_name: @user.name_for_index)
      ajax_redirect(users_path(page: params[:page], key: params[:key]))
    else
      show_validation_errors(:user)
    end
  end

  def associate_app
    @user.set_access_to_app(@app)
    render partial: 'users/form/edit_role_by_app_environment', locals: {app: @app}
  end

  def disassociate_app
    @user.remove_direct_access_of_app(@app)
    render text: ''
  end

  # TODO: remove as the feature was removed
  def set_role_for_environment
    team_id = params[:team_id].blank? ? nil : params[:team_id]
    assigned_app = @user.assigned_apps.find_by_app_id_and_team_id(@app.id, team_id)
    assigned_environment = assigned_app.assigned_environments.find_or_create_by_environment_id(params[:environment_id])
    if params[:role].blank?
      assigned_environment.destroy
    else
      assigned_environment.update_attribute(:role, params[:role])
    end
    render nothing: true
  end

  def destroy
    @user = find_user

    if @user.destroyable? && @user.destroy
      flash[:success] = I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.user'))
    else
      flash[:error] = I18n.t('activerecord.notices.not_deleted', model: I18n.t('activerecord.models.user'))
    end
    redirect_to users_path(page: params[:page], key: params[:key])
  end

  def bladelogic
    @users_for_select = User.active.by_first_name
    @users_for_select = @users_for_select.unshift(User.new)
    @bladelogic_users = BladelogicUser.all.paginate page: current_pagination_page, per_page: 15
    @last_import_date = @bladelogic_users.map { |u| u.created_at }.max
    @last_import_users = BladelogicUser.find_all_by_created_at(@last_import_date)
  end

  def rbac_import
    size = BladelogicUser.rbac_import
    if size
      flash[:success] = I18n.t(:'user.imported_from_bladelogic', size: size)
    else
      flash[:error] = I18n.t(:error_connecting_to_bladelogic)
    end

    redirect_to bladelogic_users_path
  end

  def update_bladelogic_user
    bladelogic_user = BladelogicUser.find_by_id(params[:bladelogic_user_id])
    unless bladelogic_user
      render nothing: true, status: 400
      return
    end

    if bladelogic_user.update_attributes(params[:bladelogic_user])
      render nothing: true, status: 200
    else
      render nothing: true, status: 400
    end
  end

  def forget_password # Render forgot_password
  end

  def reset_password
    @user = User.find_by_email_and_login(params[:email], params[:uid])
    if @user
      # This should be a reset_password action on the model so it can be called from rest or anywhere
      # with reliable results.
      if @user.reset_password!
        flash[:success] = I18n.t(:'user.password_generated_and_sent', user_email: @user.email)
      else
        flash[:error] = I18n.t(:'user.email_not_delivered_to', user_email: @user.email)
      end
      redirect_to login_path
    else
      flash[:error] = I18n.t(:'user.not_recognized')
      render action: 'forgot_password'
    end
  end

  def change_password
    @user = User.find(current_user)
  end

  # Update new password in database
  def update_password
    @user = User.find(params[:id])
    password = params[:user][:password].empty? ? @user.encrypted_password : params[:user][:password]
    password_confirmation = params[:user][:password_confirmation]
    current_password = params[:user][:current_password]
    if @user.change_password!(password, password_confirmation, current_password)
      flash[:notice] = I18n.t(:'user.password_changed')
      ajax_redirect(root_path)
    else
      show_error_messages(:user)
    end
  end

  def forgot_userid
    if request.post?
      @user = find_user_by_email
      if @user.nil?
        flash.now[:error] = I18n.t(:'user.provide_details_for_security_question')
        show_general_error_messages(flash[:error])
      else
        answer = params[:answer].blank? ? params[:answer] : params[:answer].downcase
        if @user.security_answer.answer.eql?(answer)
          begin
            Notifier.delay.login(@user)
            flash[:success] = I18n.t(:'user.email_delivered_with_id', user_email: @user.email)
          rescue Exception
            @delivery_error = true
            flash.now[:error] = I18n.t(:'user.email_not_delivered')
          end

          if @delivery_error
            show_general_error_messages(flash[:error])
          else
            ajax_redirect(login_url)
          end
        else
          flash.now[:error] = I18n.t(:'user.answer_matches_not_with_email')
          show_general_error_messages(flash[:error])
        end
      end
    end
  end

  def get_security_question
    @user = find_user_by_email
    respond_to do |format|
      @div = 'question'
      if @user.nil?
        @div_content = I18n.t(:'forgot_userid.incorrect_email')
      else
        sq_index = @user.security_answer.try(:question_id)
        @div_content = sq_index.nil? ? I18n.t('forgot_userid.security_question_not_exist') : SecurityAnswer::SECURITY_QUESTIONS.index(sq_index)
      end
      format.js { render template: 'misc/update_div.js.erb', content_type: 'application/javascript' }
    end
  end

  def calendar_preferences
    @calendar_fields = Calendar::FIELDS
    @user = User.find(current_user)
    if request.post?
      if @user.update_attribute(:calendar_preferences, params[:user][:calendar_preferences])
        flash[:success] = I18n.t(:'calendar.preferences_updated')
      else
        flash[:success] = I18n.t(:'calendar.preferences_not_updated')
      end
    end
  end

  def update_last_response
    current_user.update_last_response_time
    @logged_in_users = User.active.currently_logged_in(Time.now, current_user.id).all(select: 'id')
    respond_to do |format|
      format.json do
        render json: @logged_in_users.map(&:id).join(',').to_json
      end
    end
  end

  def request_list_preferences
    if request.post?
      preference = current_user.request_list_preferences.find(params[:id])
      preference.update_attributes(params[:preference])
      render partial: 'users/preferences/request_list_row', locals: {pref: preference}
    else
      Preference.request_list_for(current_user)
    end
  end

  def step_list_preferences
    if request.post?
      preference = Preference.find_by_id_and_user_id(params[:id], current_user.id)
      if preference.blank?
        render nothing: true
      else
        preference.update_attributes(params[:preference])
        render partial: 'users/preferences/step_list_row', locals: {pref: preference}
      end
    else
      Preference.step_list_for(current_user)
    end
  end

  def reset_request_preferences
    Preference.reset_request_list_for(current_user)
    render template: 'users/request_list_preferences'
  end

  def reset_step_preferences
    Preference.reset_step_list_for(current_user)
    render template: 'users/step_list_preferences'
  end

  def applications
    user = User.find(params[:id])
    render text: options_from_model_association(user, :apps)
  end

  protected

  def find_app
    @app = App.find(params[:app_id])
  end

  def find_user
    @user = User.find params[:id]
  end

  def find_user_by_email
    User.find_by_email(params[:email])
  end

  def forgot_password_enabled
    unless GlobalSettings.forgot_password?
      flash[:error] = I18n.t(:page_does_not_exist)
      redirect_to login_path
    end
  end

  private

    def parse_group_ids
      if params[:user][:group_ids].present?
        params[:user][:group_ids] = params[:user][:group_ids].gsub(/\[|\]/, '').split(',').map(&:to_i)
      end
    end

end
