class RolePermission < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission

  acts_as_audited protect: false

  def self.clean_removed
    ActiveRecord::Base.connection.execute(
      'DELETE FROM role_permissions WHERE NOT EXISTS (SELECT permissions.id FROM permissions WHERE permissions.id = role_permissions.permission_id)'
    )
  end
end
