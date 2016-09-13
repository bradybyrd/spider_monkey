require 'permissions_list'

class PermissionPersister
  def persist
    Permission.delete_all
    permissions = initialize_tree(permissions_tree)
    Permission.import(permissions)
    RolePermission.clean_removed
  end

  private

  def initialize_tree(permissions, collection = [])
    permissions.each do |permission_attrs|
      puts "TREE: #{permission_attrs.inspect}"
      unless permission_attrs['id'].blank?
        permission = Permission.new(permission_attrs.except('items'))
        permission.id = permission_attrs['id']
        collection << permission
      end
      initialize_tree(permission_attrs['items'], collection) unless permission_attrs['items'].blank?
    end

    collection
  end

  def permissions_tree
    ::PermissionsList.new.permissions_tree
  end
end