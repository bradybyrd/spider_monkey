################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module UsersHelper

  def class_for_role_radio_button
    @class_for_role_radio_button = @user.new_record? ? '' : 'spinner user_default_roles'
  end

  def welcome_with_name
    return unless current_user
    welcome_message = 'Welcome '
    welcome_message += if current_user.first_time_login?
      current_user.to_label
    else
      "Back, #{h(current_user.name)}"
    end
    welcome_message
  end

  def user_groups_list(user)
    if user.groups.any?
      options = {}
      options[:only_names] = true
      ListBuilder.new(UserGroupsPresenter.new(user), options).display_list
    end
  end

  def users_sub_tabs
    [User, Group, Team, Role].map { |klass| users_sub_tab klass }.join.html_safe
  end

  def users_sub_tab(klass)
    sub_tab klass.name.pluralize if can? :list, klass.new
  end

  def password_changable?(user_for, user_by)
    permission_action = user_for.new_record? ? :create : :edit
    current_user_authenticated_via_rpm? &&
      GlobalSettings.default_authentication_enabled? &&
      ( user_by == user_for || can?(permission_action, user_for))
  end
end
