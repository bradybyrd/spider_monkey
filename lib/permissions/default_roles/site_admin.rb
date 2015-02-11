module DefaultRoles
  class SiteAdmin < RoleCreator
    ID = 1
    NAME = 'Site Admin'
    
    def permissions
      [ system_tab_permission,
        users_subtab_full_permissions,
        groups_subtab_full_permissions,
        teams_subtab_full_permissions,
        roles_subtab_full_permissions ].flatten
    end

    def system_tab_permission
      permissions_list.scope('Main Tabs').permission('System')
    end

    def users_subtab_full_permissions
      permissions_list.all_from('View Users list')
    end

    def groups_subtab_full_permissions
      permissions_list.all_from('View Groups list')
    end

    def teams_subtab_full_permissions
      permissions_list.all_from('View Teams list')
    end

    def roles_subtab_full_permissions
      permissions_list.all_from('View Roles list')
    end
  end
end
