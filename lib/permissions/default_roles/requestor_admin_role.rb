module DefaultRoles
  class RequestorAdminRole < RoleCreator
    ID = 9
    NAME = 'Requestor Admin'

    def permissions
      [ main_tabs_permissions,
        dashboard_permissions,
        plans_permissions,
        requests_permissions,
        reports_permissions,
        applications_permissions,
        environment_permissions ].flatten
    end

    private

    def main_tabs_permissions
      permissions_list.scope('Main Tabs').permissions_by_names [
        'Dashboard',
        'Plans',
        'Requests',
        'Reports',
        'Applications',
        'Environment' ]
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

    def applications_permissions
      scope = permissions_list.scope('Applications Permissions')
      permissions = scope.permissions_by_names [
        'View Applications list',
        'Inspect Application',
        'Create Application',
        'Edit Application',
        'Make Inactive/Active',
        'Add/Remove Environments',
        'Copy All Components to All Environments',
        'Add/Remove Servers to Components/Associate with Servers',
        'Remove Component from Environment',
        'Clone Environment Components',
        'Reorder Components',
        'Reorder Environments',
        'Export Application'
      ]
      permissions += scope.all_from('Manage Components')
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
  end
end