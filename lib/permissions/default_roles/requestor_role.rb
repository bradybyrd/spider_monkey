module DefaultRoles
  class RequestorRole < RoleCreator
    ID = 4
    NAME = 'Requestor'

    def permissions
      [ main_tabs_permissions,
        dashboard_permissions,
        plans_permissions,
        requests_permissions,
        reports_permissions ].flatten
    end
    
    private

    def main_tabs_permissions
      permissions_list.scope('Main Tabs').permissions_by_names [
        'Dashboard',
        'Plans',
        'Requests',
        'Reports' ]
    end

    def dashboard_permissions
      permissions_list.all_from('Dashboard Permissions')
    end

    def plans_permissions
      permissions_list.scope('Plans Permissions').permissions_by_names [
        'View Plans list',
        'Inspect Plans',
        'Manage Plans',
        'View Tickets Summary Report',
        'View Tickets list',
        'View Routes list',
        'Inspect Route',
        'View Projects list' ]
    end

    def requests_permissions
      permissions = []
      scope = permissions_list.scope('Requests Permissions')

      permissions += scope.permissions_by_names [
        'View Requests list',
        'View created Requests list',
        'Inspect Request',
        'Import Request',
        'Create Requests',
        'Clone Request',
        'Modify Requests Details',
        'Apply Template',
        'Update Notes',
        'Change Notification Options',
        'Edit Component Versions',
        'Reorder Steps',
        'Plan Request',
        'Cancel Request',
        'Problem Request',
        'Resolve Request',
        'Hold Request',
        'Reopen Request',
        'Create Template',
        'Create Procedure',
        'Choose Template',
        'Add Procedure',
        'Export as XML Request',
        'Export as PDF Request',
        'Export HTML' ]

      permissions += scope.all_from('Inspect Steps')

      permissions += scope.permissions_by_names [
        'View Coordination Summary',
        'View Activity Summary',
        'View Property Summary',
        'View Calendar',
        'View Currently Running Steps' ]

      remove_permissions(permissions, 'Select Package', 'Select Instance')
    end

    def reports_permissions
      permissions_list.all_from('Reports Permissions')
    end
  end
end
