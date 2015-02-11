module DefaultRoles
  class DeployerAdminRole < RoleCreator
    ID = 8
    NAME = 'Deployer Admin'

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
      except = ['Select Package', 'Select Instance']
      permissions_list.all_from('Requests Permissions').reject do |permission|
        except.include? permission[:name]
      end
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
        'Export Application' ]
      permissions += scope.all_from('View Routes')
      permissions
    end

    def environment_permissions
      scope = permissions_list.scope('Environment Permissions')
      permissions = permissions_list.all_from('View Properties list')
      permissions += permissions_list.all_from('Access Servers')
      permissions += permissions_list.all_from('View Components list')
      permissions += permissions_list.all_from('View Environments list')
      permissions += permissions_list.all_from('View Automation list')
      permissions += permissions_list.all_from('Access Metadata')
      permissions
    end

    def system_permissions
      scope = permissions_list.scope('System Permissions')
      permissions = scope.all_from('View Users list')
      permissions += scope.all_from('View Groups list')
      permissions += scope.all_from('View Teams list')
      permissions += scope.all_from('Access Settings')
      permissions += scope.all_from('View Automation Monitor')
      permissions += scope.all_from('View Integration')
      permissions
    end
  end
end