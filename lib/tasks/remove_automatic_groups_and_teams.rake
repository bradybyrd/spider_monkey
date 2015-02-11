desc 'Remove newly added teams groups and roles'

namespace :app do
  task remove_automatic_groups_and_teams: :environment do
    puts 'Deleting automatically created groups and teams'
    new_groups = Group.where("name like '%-group%'")
    puts "#-- Groups --#\nid | name | active"
    new_groups.each do |group|
      puts "#{group.id} | #{group.name} | #{group.active}"
      group.destroy
    end
    puts 'Groups deleted successfully'
    new_teams = Team.where("name like '%created Team%'")
    puts "#-- Teams --#\nid | name"
    new_teams.each do |team|
      puts "#{team.id} | #{team.name}"
      team.destroy
    end
    puts 'Teams deleted successfully'
  end
end