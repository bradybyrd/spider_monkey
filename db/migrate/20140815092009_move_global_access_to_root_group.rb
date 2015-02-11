class MoveGlobalAccessToRootGroup < ActiveRecord::Migration
  def up
    root_group = Group.find_by_root(true)
    return if root_group.nil?

    User.update_all({root: true}, {global_access: true})
    root_user_ids = User.where(root: true).pluck(:id)
    root_group.user_ids = (root_group.user_ids + root_user_ids).uniq
  end

  def down
    # these changes cannot be reverted
  end
end
