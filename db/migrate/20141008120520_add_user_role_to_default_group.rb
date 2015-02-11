class AddUserRoleToDefaultGroup < ActiveRecord::Migration
  class Group < ActiveRecord::Base
  end

  class GroupRole < ActiveRecord::Base
    attr_accessible :group_id, :role_id
  end

  def initialize
    super
    Group.reset_column_information
    GroupRole.reset_column_information
    @default_group = Group.where(name: '[default]').first
  end

  def up
    assign_user_role if @default_group.present? && !user_role_assigned?
  end

  def down
    unassign_user_role if @default_group.present?
  end

  private

  def assign_user_role
    GroupRole.create group_role_attributes
  end

  def unassign_user_role
    GroupRole.destroy_all group_role_attributes
  end

  def user_role_assigned?
    GroupRole.exists? group_role_attributes
  end

  def group_role_attributes
    { group_id: @default_group.id, role_id: DefaultRoles::UserRole::ID }
  end
end
