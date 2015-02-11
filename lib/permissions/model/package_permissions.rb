module Permissions
  module Model
    class PackagePermissions

      def edit?(package, user)
        has_permission?("edit", package, user)
      end

      def create_instance?(package, user)
        has_permission?('create_instance', package, user)
      end

      def view_instances?(package, user)
        has_permission?('view_instances', package, user)
      end

      private

      def has_permission?(action, package, user)
        Permission.
          joins(roles: { groups: { teams: [:users, { apps: :packages }] } }).
          where(
            packages: { id: package.id },
            users: { id: user.id },
            permissions: { action: action, subject: "Package" }
          ).
          exists?
      end

    end
  end  
end