module DefaultRoles
  class ExecutorRole < RoleCreator
    ID = 6
    NAME = 'Executor'

    def permissions
      permissions = []
      # Main Tabs
      scope = permissions_list.scope('Main Tabs')
      permissions << scope.permission('Dashboard')
      permissions << scope.permission('Plans')
      permissions << scope.permission('Requests')
      permissions << scope.permission('Reports')
      # Dashboard Permissions
      permissions += permissions_list.all_from('Dashboard Permissions')
      # Plans Permissions
      scope = permissions_list.scope('Plans Permissions')
      permissions << scope.permission('View Plans list')
      permissions << scope.permission('Inspect Plans')
      permissions << scope.permission('Manage Plans')
      permissions << scope.permission('View Routes list')
      permissions << scope.permission('Inspect Route')
      permissions << scope.permission('View Tickets list')
      permissions << scope.permission('View Projects list')
      # Requests Permissions
      scope = permissions_list.scope('Requests Permissions')
      permissions << scope.permission('View Requests list')
      permissions << scope.permission('Inspect Request')
      permissions << scope.permission('Start Request')
      permissions << scope.permission('Problem Request')
      permissions << scope.permission('Hold Request')

      permissions << scope.permission('Inspect Steps')
      permissions << scope.permission('View General tab')
      permissions << scope.permission('View Automation tab')
      permissions << scope.permission('View Notes tab')
      permissions << scope.permission('View Documents tab')
      permissions << scope.permission('View Properties tab')
      permissions << scope.permission('View Server properties tab')
      permissions << scope.permission('View Design tab')
      permissions << scope.permission('Run Steps')
      permissions << scope.permission('View Coordination Summary')
      permissions << scope.permission('View Activity Summary')
      permissions << scope.permission('View Property Summary')
      permissions << scope.permission('View Calendar')
      permissions << scope.permission('View Currently Running Steps')
      # Reports Permissions
      permissions += permissions_list.all_from('Reports Permissions')
      permissions
    end

  end
end
