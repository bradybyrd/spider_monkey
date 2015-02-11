module ApplicationPermissionsInitializtaionHelper
  def prepare_user_permissions
    user = User.current_user
    @app1 = create :app
    @app2 = create :app
    @perms1  = [
      create(:permission, subject: "Environment", action: :create),
      create(:permission, subject: "Environment", action: :view)
    ]
    @perms1_1 = [
      create(:permission, subject: "Environment", action: :delete)
    ]
    @perms2 = [
      create(:permission, subject: "Request", action: :create),
      create(:permission, subject: "Request", action: :delete)
    ]
    @perms2_1 = [
      create(:permission, subject: "Request", action: :update)
    ]
    @role1  = create(:role, permissions: @perms1)
    @role2  = create(:role, permissions: @perms2)

    @role3  = create(:role, permissions: @perms1_1)
    @role4  = create(:role, permissions: @perms2_1)

    @group1 = create(:group, roles: [@role1])
    @group2 = create(:group, roles: [@role2])

    @group3 = create(:group, roles: [@role3, @role4])

    user.groups << @group1
    user.groups << @group2

    user.save

    @team1 = create(:team_with_apps_and_groups, apps: [@app1], groups: [@group1])
    @team2 = create(:team_with_apps_and_groups, apps: [@app2], groups: [@group3])
    @team3 = create(:team_with_apps_and_groups, apps: [@app2], groups: [@group1, @group2])

  end
end
