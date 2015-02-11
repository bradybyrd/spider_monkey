namespace :assigned_apps do
  desc 'Cleans Assigned Apps table from duplicates and associated Assigned Environments'
  task clear_duplicates: :environment do
    Kernel.puts "Assigned environment is depricated, and will be removed in BRPM 4.6"
    puts 'Working...'

    ids_to_del = []

    duplicates = AssignedApp.select('app_id, team_id, user_id, min(id) as min_id').
        group(:app_id, :team_id, :user_id).having('count(*)>1')

    puts "Duplicates: #{duplicates.length}"
    puts "app_id\tteam_id\tuser_id\tmin_id"
    duplicates.each do |dup|
      app_id = dup.app_id
      team_id = dup.team_id
      user_id = dup.user_id
      min_id = dup.min_id

      puts "#{app_id}\t#{team_id}\t#{user_id}\t#{min_id}"

      all_ids = AssignedApp.where('app_id = :app_id AND team_id = :team_id AND user_id = :user_id',
                                  {app_id: app_id, team_id: team_id, user_id: user_id}).pluck(:id)
      puts "All: #{all_ids}"

      dupl_ids = AssignedApp.where('app_id = :app_id AND team_id = :team_id AND user_id = :user_id AND id > :id',
                                   {app_id: app_id, team_id: team_id, user_id: user_id, id: min_id}).pluck(:id)
      puts "Del: #{dupl_ids}"

      ids_to_del += dupl_ids

      puts
    end

    ids_to_del.sort!

    puts "All to del: #{ids_to_del}"

    # follow line delete duplicates from assigned_apps table
    # dependent records from assigned_environments also delete (since destroy not delete used)
    AssignedApp.scoped.extending(QueryHelper::WhereIn).
        where_in('id', ids_to_del).destroy_all if ids_to_del.count > 0

    puts 'Done.'
  end
end
