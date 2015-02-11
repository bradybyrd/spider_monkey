class TestPermissionGranter

  def initialize(permissions)
    @permissions = permissions
  end

  def <<(names, scope = nil)
    [*names].each do |name|
      @permissions << PermissionFetcher.new(name, permissions_list).find_or_create
    end
    self
  end

  def add_from_scope(scope, name)
    scope = permissions_list.scope(scope)
    @permissions << PermissionFetcher.new(name, scope).find_or_create
  end

  private

  def permissions_list
    @permissions_list ||= PermissionsList.new
  end

  class PermissionFetcher
    def initialize(name, permissions_list)
      @name, @permissions_list = name, permissions_list
    end

    def find_or_create
      find || create
    end

    private

    attr_reader :permissions_list, :name

    def find
      Permission.where(find_in_list_by_name).first
    end

    def create
      FactoryGirl.create(:permission, find_in_list_by_name)
    end

    def find_in_list_by_name
      permissions_list.permission(name) || permission_not_found
    end

    def permission_not_found
      raise "'#{name}' wasn't found in the permissions list"
    end
  end

end
