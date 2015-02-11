# Usage:
# Find one by name: permissions_list.permission('Permission Name') # {id: 1, name: 'Permission Name', ...}
# Find all children: permissions_list.scope('Permission Name').permissions does not include 'Permission Name'
# Find all with children: permissions_list.all_from('Permission Name') it includes 'Permission Name'
# Create scope to prevent duplicates: permissions_list.scope('Requests Permissions')
class PermissionsList
  attr_reader :permissions, :permissions_tree

  def initialize(tree = nil)
    if tree.nil?
      @permissions_tree = load_tree
    else
      @permissions_tree = tree
    end

    @permissions = permissions_list
  end

  # [{id: 1, name: 'Permission Name', ...}, ...]
  def all_from(name)
    permissions_list([node(name)])
  end

  # {id: 1, name: 'Permission Name', ...}
  def permission(name)
    permission = permissions.find {|permission| permission[:name] == name }
    raise "'#{name}' wasn't found in the permissions list" unless permission
    permission
  end

  def permissions_by_names(names)
    names.map { |name| permission(name) }
  end

  # PermissionsList
  def scope(name)
    self.class.new(node(name)['items'])
  end

  private

  def load_tree
    file = File.join(Rails.root, 'data', 'permissions.yml')
    YAML.load_file(file)
  end

  def permissions_list(tree = nil)
    list = []
    tree = permissions_tree if tree.nil?
    tree.each do |item|
      list << item.except('items').symbolize_keys if item.has_key?('id')
      list += permissions_list(item['items']) if item.has_key?('items')
    end
    list
  end

  def node(name, tree = nil)
    tree = permissions_tree if tree.nil?
    tree.each do |permission|
      return permission if permission['name'] == name
      node = node(name, permission['items']) if permission.has_key?('items')
      return node unless node.nil?
    end
    nil
  end
end
