module DefaultRoles
  class RoleCreator
    attr_reader :permissions_list

    def initialize(permissions_list = nil)
      @permissions_list = permissions_list
    end

    def permission_ids
      permissions.map { |p| p[:id] }
    end

    def create
      create_role
      update_permissions
    end

    def update_permissions
      self.class.without_auditing do
        Role.find(self.class::ID).update_attributes permission_ids: permission_ids
      end
    end

    def permissions
      raise NotImplementedError.new("You must implement permissions.")
    end

    def self.destroy
      without_auditing do
        Role.destroy_all(name: self::NAME)
        Role.destroy_all(id: self::ID)
      end
    end

    def self.without_auditing
      RolePermission.disable_auditing
      Role.disable_auditing
      yield
      RolePermission.enable_auditing
      Role.enable_auditing
    end

    private

    def create_role
      Role.connection.set_identity_insert('roles', true) if MsSQLAdapter
      role = Role.new name: self.class::NAME
      role.id = self.class::ID
      role.save_without_auditing
      Role.connection.set_identity_insert('roles', false) if MsSQLAdapter
      ActiveRecord::Base.connection.reset_pk_sequence!('roles') if ActiveRecord::Base.connection.respond_to?(:reset_pk_sequence!)
    end

    def remove_permissions(permissions, *permission_names)
      permissions.flatten.reject do |permission|
        permission[:name].in?(permission_names)
      end
    end
  end
end
