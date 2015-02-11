require 'environment_permission_scoper'

module PermissionScope
  def self.included(klass)
    klass.class_eval do
      scope :by_ability, ->(action, user) {
        return scoped if user.admin?
        EnvironmentPermissionScoper.new(user, scoped).entities_by_ability(action)
      }
    end
  end
end