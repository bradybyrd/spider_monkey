module DefaultRoles
  class UserAdminRole < RoleCreator
    ID = 10
    NAME = 'User Admin'

    def permissions
      permissions = []
      # Main Tabs
      scope = permissions_list.scope('Main Tabs')
      permissions << scope.permission('Dashboard')
      permissions << scope.permission('Plans')
      permissions << scope.permission('Requests')
      permissions << scope.permission('Reports')
      permissions << scope.permission('Applications')
      permissions << scope.permission('Environment')

      # Dashboard Permissions
      permissions += permissions_list.all_from('Dashboard Permissions')

      # Plans Permissions
      permissions += permissions_list.all_from('Plans Permissions')

      # Requests Permissions
      scope = permissions_list.scope('Requests Permissions')
      permissions << scope.permission('View Requests list')
      permissions << scope.permission('Inspect Request')
      permissions << scope.permission('Modify Requests Details')
      permissions << scope.permission('Start Automatically')
      permissions << scope.permission('Update Notes')
      permissions << scope.permission('Change Notification Options')
      permissions << scope.scope('Manage Requests').permission('Edit Component Versions')
      permissions << scope.permission('Reorder Steps')
      permissions << scope.permission('Start Request')
      permissions << scope.permission('Cancel Request')
      permissions << scope.permission('Problem Request')
      permissions << scope.permission('Resolve Request')
      permissions << scope.permission('Hold Request')
      permissions << scope.permission('Reopen Request')
      permissions << scope.permission('Delete Request')
      permissions << scope.permission('Create Procedure')
      permissions << scope.permission('Add Procedure')
      permissions << scope.permission('Export as XML Request')
      permissions << scope.permission('Export as PDF Request')
      permissions << scope.permission('Export HTML')

      permissions << scope.permission('Inspect Steps')
      permissions << scope.permission('View General tab')
      permissions << scope.permission('View Automation tab')
      permissions << scope.permission('View Notes tab')
      permissions << scope.permission('View Documents tab')
      permissions << scope.permission('View Properties tab')
      permissions << scope.permission('View Server properties tab')
      permissions << scope.permission('View Design tab')
      permissions << scope.permission('Add New Step')
      permissions << scope.permission('Edit Steps')
      permissions << scope.permission('Edit Owner')
      permissions << scope.permission('Edit Task/Phase')
      permissions += scope.all_from('Select Component')
      permissions << scope.permission('Delete Steps')
      permissions << scope.permission('Turn On/Off')
      permissions << scope.permission('Reset Steps')
      permissions << scope.permission('Run Steps')
      permissions << scope.permission('Edit Execution Conditions for Procedure')
      permissions << scope.permission('Edit Procedure')
      permissions << scope.permission('Add Serial Procedure step')
      permissions << scope.permission('Remove Procedure')
      permissions << scope.permission('View Coordination Summary')
      permissions << scope.permission('View Activity Summary')
      permissions << scope.permission('View Property Summary')
      permissions << scope.permission('View Calendar')
      permissions << scope.permission('View Currently Running Steps')

      # Reports Permissions
      permissions += permissions_list.all_from('Reports Permissions')

      # Applications Permissions
      scope = permissions_list.scope('Applications Permissions')
      permissions << scope.permission('View Applications list')
      permissions << scope.permission('Inspect Application')
      permissions << scope.permission('Create Application')
      permissions << scope.permission('Edit Application')
      permissions << scope.permission('Make Inactive/Active')
      permissions << scope.permission('Add/Remove Environments')
      permissions += scope.all_from('Manage Components')
      permissions << scope.permission('Copy All Components to All Environments')
      permissions << scope.permission('Add/Remove Servers to Components/Associate with Servers')
      permissions << scope.permission('Remove Component from Environment')
      permissions << scope.permission('Clone Environment Components')
      permissions << scope.permission('Reorder Components')
      permissions << scope.permission('Reorder Environments')
      permissions << scope.permission('Export Application')
      permissions += scope.all_from('View Routes')

      # Environment Permissions
      scope = permissions_list.scope('Environment Permissions')
      permissions += scope.all_from('View Properties list')
      permissions += scope.all_from('Access Servers')
      permissions += scope.all_from('View Components list')
      permissions += scope.all_from('View Environments list')
      permissions += scope.all_from('View Automation list')
      permissions += scope.all_from('Access Metadata')

      permissions
    end
  end
end
