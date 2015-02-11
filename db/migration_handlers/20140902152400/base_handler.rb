class BaseHandler
  GROUP_SUFFIX = "-group"
  ADMIN_SUFFIX = '_admin'

  ROLES_HASH = {
    not_visible: 'Not Visible',
    user: 'User',
    deployment_coordinator: 'Coordinator',
    deployer: 'Deployer',
    requestor: 'Requestor',
    executor: 'Executor',
    user_admin: 'User Admin',
    deployment_coordinator_admin: 'Coordinator Admin',
    deployer_admin: 'Deployer Admin',
    requestor_admin: 'Requestor Admin',
    executor_admin: 'Executor Admin'
  }

  PERMANENT_ROLES = ['not_visible']
  SITE_ADMIN = "Site Admin"
  ROOT_GROUP = 'Root'

  def initialize
    @group_number = {}
    @current_time = Time.current.to_formatted_s(:db)
  end     

  def to_group_name(role_name)
    if role_name == ROOT_GROUP
      role_name
    else
      "#{role_name} Group"
    end
  end

  def to_role_name(str_role)
    ROLES_HASH[str_role.intern].to_s
  end

  def to_old_role(role_name)
   ROLES_HASH.rassoc(role_name).first.to_s 
  end
end