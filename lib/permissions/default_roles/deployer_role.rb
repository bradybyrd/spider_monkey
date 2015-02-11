module DefaultRoles
  class DeployerRole < RoleCreator
    ID = 3
    NAME = 'Deployer'

    def permissions
      [ main_tabs_permissions,
        dashboard_permissions,
        plans_permissions,
        requests_permissions,
        reports_permissions,
        application_permissions,
        environment_permissions,
        system_permissions ].flatten
    end

    private

    def main_tabs_permissions
      permissions_list.all_from('Main Tabs')
    end

    def dashboard_permissions
      permissions_list.all_from('Dashboard Permissions')
    end

    def plans_permissions
      permissions_list.all_from('Plans Permissions')
    end

    def requests_permissions
      permissions = permissions_list.all_from('Requests Permissions')
      remove_permissions(permissions, 'Select Package', 'Select Instance')
    end

    def reports_permissions
      permissions_list.all_from('Reports Permissions')
    end

    def application_permissions
      scope = permissions_list.scope('Applications Permissions')
      permissions = scope.permissions_by_names [
        'View Applications list',
        'Inspect Application',
        'Create Application',
        'Edit Application',
        'Make Inactive/Active',
        'Add/Remove Environments' ]
      permissions += scope.all_from('Manage Components')
      permissions += scope.permissions_by_names [
        'Copy All Components to All Environments',
        'Add/Remove Servers to Components/Associate with Servers',
        'Remove Component from Environment',
        'Clone Environment Components',
        'Reorder Components',
        'Reorder Environments',
        'Export Application',
        'View Routes',
        'Inspect Routes' ]
      permissions
    end

    def environment_permissions
      scope = permissions_list.scope('Environment Permissions')
      permissions = scope.all_from('View Properties list')
      permissions += scope.all_from('Access Servers')
      permissions += scope.all_from('View Components list')
      permissions += scope.all_from('View Environments list')
      permissions += scope.all_from('View Automation list')
      permissions << scope.permission('Access Metadata')
      permissions += scope.all_from('View Categories list')
      permissions += scope.all_from('View Environment Types list')
      permissions += scope.all_from('View Plan Templates list')
      permissions += scope.all_from('View Lists list')
      permissions += scope.all_from('View Procedures list')
      permissions += scope.all_from('View Processes list')
      permissions += scope.all_from('View Releases list')
      permissions += scope.all_from('View Request Templates list')
      permissions += scope.all_from('View Tickets list')
      permissions += scope.all_from('View Version Tags list')
      permissions += scope.all_from('View Work Tasks list')
      permissions += scope.all_from('View Deployment Windows list')
    end

    def system_permissions
      scope = permissions_list.scope('System Permissions')
      permissions = [ scope.permission('Access Settings') ]
      permissions += scope.all_from('View Automation Monitor')
      permissions += scope.all_from('View Integration')
      permissions
    end
  end
end
