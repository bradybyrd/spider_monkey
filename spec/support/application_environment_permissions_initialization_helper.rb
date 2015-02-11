module ApplicationEnvironmentPermissionsInitializtaionHelper
  def prepare_user_permissions(user_ = nil)
    user = user_ || User.current_user
    @app1 = create :app
    @env1 = create(:environment, apps: [@app1])
    @env2 = create(:environment, apps: [@app1])
    @app2 = create :app
    @env3 = create(:environment, apps: [@app2])
    @env4 = create(:environment, apps: [@app2])

    @app_env1 = @app1.application_environments.where("environment_id = ?", @env1.id).first
    @app_env2 = @app1.application_environments.where("environment_id = ?", @env2.id).first
    @app_env3 = @app2.application_environments.where("environment_id = ?", @env3.id).first
    @app_env4 = @app2.application_environments.where("environment_id = ?", @env4.id).first

    @perms1  = [
      create(:permission, subject: "VersionTag", action: :create),
      create(:permission, subject: "VersionTag", action: :view)
    ]
    @perms1_1 = [
      create(:permission, subject: "VersionTag", action: :delete)
    ]
    @perms1_2 = [ # not assigned to user
      create(:permission, subject: "VersionTag", action: :forbidden)
    ]
    @perms2 = [
      create(:permission, subject: "Request", action: :create),
      create(:permission, subject: "Request", action: :delete)
    ]
    @perms2_1 = [
      create(:permission, subject: "Request", action: :update)
    ]
    @perms2_2 = [ # not assigned to user
      create(:permission, subject: "Request", action: :forbidden)
    ]
    @role1  = create(:role, permissions: @perms1)
    @role2  = create(:role, permissions: @perms2)

    @role1_1  = create(:role, permissions: @perms1_1)
    @role2_1  = create(:role, permissions: @perms2_1)


    @role3  = create(:role, permissions: (@perms1_2 + @perms2_2)) # not assigned to user

    @group1 = create(:group, roles: [@role1, @role1_1])
    @group2 = create(:group, roles: [@role2, @role2_1])

    @group3 = create(:group, roles: [@role3]) # not assigned to user

    user.groups << @group1
    user.groups << @group2

    user.save

    @team1 = create(:team_with_apps_and_groups, apps: [@app1], groups: [@group1, @group2])
    @team2 = create(:team_with_apps_and_groups_env_roles, apps: [@app2],
      groups_config:[{
        group: @group1,
        app_env_roles:[{
          app: @app2,
          env: @env3,
          role: @role1
        },{
          app: @app2,
          env: @env4,
          role: @role1
        }]
      },{
        group: @group2,
        app_env_roles:[{
          app: @app2,
          env: @env3,
          role: @role2
        }]
      }]
    )
  end
end