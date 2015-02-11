desc "Reset First Time login on users"

namespace :app do
  task :set_first_time_login => :environment do
    numdone = 0
    User.all.each do |user|
      user.update_attributes( :first_time_login, 0 )
      numdone += 1
    end
    puts "Set first time login completed: #{users.count} - users"
  end
end
      
