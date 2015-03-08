# require 'spec_helper'
# require 'yaml'
# require File.expand_path('../../../db/migrate/20140902152400_move_users_to_groups_in_teams', __FILE__)
# require File.expand_path('../../../db/migrate/20140829075903_migrate_app_assignments_to_teams', __FILE__)
#
# describe MoveUsersToGroupsInTeams do
#
#   before do
#     @my_migration_version = '20140902152400'
#     @previous_migration_version = '20140829075903'
#     @current_migration_version = ActiveRecord::Migrator.current_version
#     @migrations_path = File.expand_path('../../../db/migrate', __FILE__)
#     @current_time = Time.current.to_formatted_s(:db)
#     @migration = MoveUsersToGroupsInTeams.new
#     @app_assignment_migration = MigrateAppAssignmentsToTeams.new
#     @base_handler = BaseHandler.new
#   end
#
#   describe "#up and #down" do
#     before do
#       ActiveRecord::Migrator.migrate @migrations_path, @previous_migration_version.to_i
#       TeamSQL.create_default_team(TeamGroupsHandler::DEFAULT_TEAM_ID)
#       User.reset_column_information
#     end
#
#     after do
#       ActiveRecord::Migrator.migrate @migrations_path, @current_migration_version.to_i
#       User.reset_column_information
#     end
#
#     describe "up and down simple" do
#       it "default user roles" do
#         create_roles
#         create(:group, name: 'test', position: Group::DEFAULT_GROUP_POSITION)
#
#         users = create_users(7, [BaseHandler::ROLES_HASH[:user], BaseHandler::ROLES_HASH[:deployment_coordinator], BaseHandler::ROLES_HASH[:deployer]])
#         UserSQL.make_user_root(users[0].id)
#         (3..6).to_a.each{ |ind| UserSQL.make_user_admin(users[ind].id) }
#         UserSQL.make_user_root(users[6].id)
#
#         start_group_count = Group.count
#         user_roles = UserSQL.get_user_roles
#
#         @migration.up
#         (Group.count - start_group_count).should == 13
#
#         users[0].should part_of_groups ["Root", "User Group", '[default]']
#         users[1].should part_of_groups ["Coordinator Group", '[default]', 'test']
#         users[2].should part_of_groups ["Deployer Group", '[default]', 'test']
#         users[3].should part_of_groups ["Site Admin Group", "User Admin Group", '[default]', 'test']
#         users[4].should part_of_groups ["Site Admin Group", "Coordinator Admin Group", '[default]', 'test']
#         users[5].should part_of_groups ["Site Admin Group", "Deployer Admin Group", '[default]', 'test']
#         users[6].should part_of_groups ["Site Admin Group", "User Admin Group", "Root", '[default]', 'test']
#
#         Group.all.map(&:name).should include "[default]"
#         Team.find(TeamGroupsHandler::DEFAULT_TEAM_ID).groups.map(&:name).should == ['[default]']
#         def_group = Group.where(name: '[default]').first
#         def_group.position.should == Group::DEFAULT_GROUP_POSITION
#         (Group.all - [def_group]).each do |group|
#           group.position.should > Group::DEFAULT_GROUP_POSITION
#         end
#
#         @migration.down
#
#         Group.count.should == start_group_count
#         Group.all.map(&:name).should_not include "[default]"
#         UserSQL.admin?(users[6].id).should be_truthy
#         UserSQL.root?(users[6].id).should be_truthy
#         UserSQL.get_user_roles.should =~ user_roles
#         Team.find(TeamGroupsHandler::DEFAULT_TEAM_ID).groups.map(&:name).should_not include ('[default]')
#       end
#     end
#
#     it "successfully up and down to pre up state all cases" do
#       users, apps, team_ids = prepare_data
#       start_group_count = Group.count
#       user_roles = UserSQL.get_user_roles
#
#       @migration.up
#
#       # 1- [default], 1 - site-admin, 1 - root, 11 - default, 1 (team-1) + 1 (team-2) + 3 (team-3)
#       (Group.count - start_group_count).should == 19
#       # everywhere +1 default group
#       users[0].groups.count.should == 3 # not-visible and group by user role
#       users[1].groups.count.should == 3
#       users[2].groups.count.should == 4 # in 2 teams
#       users[3].groups.count.should == 3
#       users[4].groups.count.should == 3
#       users[5].groups.count.should == 4 # + site admin group
#       # check that site admin user migrate to role admin group
#       users[5].groups.select{|g| BaseHandler::ROLES_HASH.values.include?(g.name) && !(g.name =~ /Admin/)}.should be_empty
#       users[6].groups.count.should == 4 # + root group
#
#       @migration.down
#
#       Group.count.should == start_group_count
#       UserSQL.admin?(users[5].id).should be_truthy
#       UserSQL.root?(users[6].id).should be_truthy
#       UserSQL.get_user_roles.should =~ user_roles
#     end
#   end
#
#   def new_default_group
#     groups = Group.all
#     group = groups.empty? ? create(:group, name: 'test group 1') : groups.first
#     GroupSQL
#   end
#
#   def monitor_groups
#     groups = ActiveRecord::Base.connection.select_all <<-SQL
#       select id, name from groups
#     SQL
#     groups_hash = {}
#     groups.each do |row|
#       groups_hash[row['id']] = row['name']
#     end
#     groups_with_roles = ActiveRecord::Base.connection.select_all <<-SQL
#       select gr.group_id, r.name
#       from group_roles gr
#         inner join roles r on r.id = gr.role_id
#     SQL
#
#     group_roles = {}
#     groups_with_roles.each do |row|
#       group_roles[groups_hash[row['group_id']]] ||= []
#       group_roles[groups_hash[row['group_id']]] << row['name']
#     end
#
#     Kernel.puts "groups: #{groups.inspect}\nroup_rolets: #{group_roles.inspect}"
#   end
#
#   def prepare_data
#     users, apps = preapare_basic_data
#     app_env_roles = prepare_app_env_roles(apps)
#     team_ids = prepare_users(users, apps, app_env_roles)
#     return users, apps, team_ids
#   end
#
#   def prepare_users(users, apps, app_env_roles)
#     team_ids = []
#     UserSQL.make_user_not_root(users[0].id)
#     team_ids << process_user(users[0], [apps[0]], [app_env_roles.first])
#
#     UserSQL.make_user_not_root(users[1].id)
#     team_ids << process_user(users[1], apps[0..1], app_env_roles[0..1])
#
#     UserSQL.make_user_not_root(users[2].id)
#     process_user(users[2], apps[0..1], app_env_roles[0..1], team_ids[1])
#     team_ids << process_user(users[2], apps[0..3], app_env_roles[0..3])
#
#     UserSQL.make_user_not_root(users[3].id)
#     process_user(users[3], [apps[0]], [app_env_roles[0]], team_ids[0])
#
#     user_5_app_env_roles = app_env_roles[0..3].collect{|hash|
#       new_hash = hash.dup
#       new_hash.keys.each{|k|
#         new_hash[k] = BaseHandler::ROLES_HASH.keys.first.to_s
#       };
#       new_hash
#     }
#
#     UserSQL.make_user_not_root(users[4].id)
#     process_user(users[4], apps[0..3], user_5_app_env_roles, team_ids[2])
#
#     UserSQL.make_user_admin(users[5].id)
#     process_user(users[5], apps[0..3], app_env_roles[0..3], team_ids[2])
#
#     app_env_roles[3][app_env_roles[3].keys.last] = app_env_roles[3][app_env_roles[3].keys.first]
#
#     UserSQL.make_user_root(users[6].id)
#     process_user(users[6], apps[0..3], app_env_roles[0..3], team_ids[2])
#
#     team_ids
#   end
#
#   def preapare_basic_data
#     create_roles
#     users = create_users(7)
#     create_environments(5)
#     apps = create_apps(4, [1,2,3,5])
#     return users, apps
#   end
#
#   def prepare_app_env_roles(apps)
#     appp_env_roles = []
#     apps.each do |app|
#       env_roles = {}
#       AppSQL.get_app_environment_ids(app.id).each_with_index do |env_id, ind|
#         env_roles[env_id] = BaseHandler::ROLES_HASH.keys[ind].to_s
#       end
#       appp_env_roles << env_roles
#     end
#     appp_env_roles
#   end
#
#   def process_user(user, apps = [], env_roles = [], team_id = nil)
#     team_id = team_id || create_team(apps, user).id
#     @app_assignment_migration.assign_user_to_team(team_id, user.id)
#
#     apps.each_with_index do |app, ind|
#       UserSQL.assign_user_to_app(user.id, app.id, team_id)
#       UserSQL.assign_user_to_app_envs(user.id, app.id, team_id, env_roles[ind])
#     end
#     team_id
#   end
#
#   def create_team(apps, user)
#     team = @app_assignment_migration.create_team_with_apps(apps.map(&:id))
#   end
#
#   def create_apps(n, envs = [])
#     apps = []
#     n.times do |index|
#       apps << create_app(envs.empty? ? rand(n) : envs[index])
#     end
#     apps
#   end
#
#   def create_app(env_count)
#     app = create :app
#     envs = Environment.limit(env_count)
#     env_count.times do |index|
#       create :application_environment, :app => app, :environment => envs[index]
#     end
#     app
#   end
#
#   def create_environments(n)
#     create_list :environment, n
#   end
#
#   def create_users(n, roles = [])
#     res = create_list :user, n
#
#     User.all.each_with_index do |u, ind|
#       SQLHelper.insert('teams_users', user_id: u.id, team_id: TeamGroupsHandler::DEFAULT_TEAM_ID, time: true)
#       new_role = roles.empty? ? BaseHandler::ROLES_HASH.values[1..5].sample : roles[ind%roles.length]
#       raise "#{new_role} : #{ind}" if new_role.blank?
#       old_role = @base_handler.to_old_role(new_role)
#       RoleSQL.assign_role_to_user(u.id, old_role)
#     end
#   end
#
#   def create_roles
#     BaseHandler::ROLES_HASH.values.each{ |role_name| create(:role, name: role_name) }
#     create(:role, name: BaseHandler::SITE_ADMIN)
#   end
# end
