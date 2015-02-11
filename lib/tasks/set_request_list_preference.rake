namespace :sr do
  namespace :requests do
    task :set_list_preferences => :environment do
      users = User.all
      users.each do |user|
        puts "Setting preference for #{user.to_label}"
        Preference.request_list_for(user)
      end
      puts "Rake complete !!!"
    end
  end
end