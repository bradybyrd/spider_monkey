module DefaultRoles
  class NotVisibleRole < RoleCreator
    ID = 12
    NAME = 'Not Visible'

    def permissions
      []
    end
  end
end