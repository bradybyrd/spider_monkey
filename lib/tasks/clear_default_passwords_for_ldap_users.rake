namespace :ldap_users do
  task clear_default_password: :environment do
    users = []
    User.order(:login).all.each do |user|
      res = user.authenticated?('testtest1')
      if res
        users << user
        puts "# #{users.size}\tid: #{user.id}\tlogin: #{user.login}"
      end
    end
    if users.size > 0
      puts "User(s) with default password: #{users.size}"
      puts "User(s) total: #{User.count}"

      puts 'Are you sure to clean up default password for all user(s) above? [y/n]'
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        users.each do |user|
          user.encrypted_password = nil
          user.password_salt = nil
          user.save(validate: false)
          puts "Password reset for #{user.login}"
        end
        puts 'Done.'
      else
        puts 'You have cancelled the task'
      end
    else
      puts 'No users with default password found'
    end
  end
end