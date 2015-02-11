namespace :app do

  namespace :users do

    desc "Rename and deactivate a user from the system. [login] parameter is required immediately after task name."
    task :rename_and_deactivate_user, [:login] => [:environment] do |t, args|
      puts "This will permanently rename and archive the user with the login: #{args.login}. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y' && args.login.present?
        begin
          puts "Locating user #{args.login}..."
          user = User.where('UPPER(login) LIKE ?', args.login.try(:upcase)).try(:first)
          if user.present?
            puts "Found user #{args.login}. Checking for admin or root..."
            if user.admin?
              puts "User is root or admin. Please downgrade this user using the BRPM UI before proceeded.  Exiting..."
            else
              puts "User is not admin or root. Deactivating..."
              # first deactivate them if they are active
              success = true
              success = user.deactivate! if user.active?
              if success
                puts "Deactivated user. Modifying unique fields to allow original login to be reused..."
                # create a unique label with time in seconds and a random number
                unique_label = "a#{Time.now.to_i}#{rand(9)}"
                # capture the length of the label to avoid hitting length limits on fields
                label_length = unique_label.length
                # make a unique email with the old domain and a unique prefix
                original_domain = user.email.split('@').try(:last) || 'example.com'
                unique_email = "#{unique_label}@#{original_domain}"
                # make a unique login by adding the prefix to the shortened original login
                unique_login = "#{user.login[0..(36 - label_length)]}.#{unique_label}"
                # adjust the last name to have archived in it
                archived_last_name = "#{user.last_name[0..(250 - label_length)]}.#{unique_label}"
                success = user.update_attributes(:email => unique_email,
                                                 :login => unique_login,
                                                 :reset_password_token => unique_login,
                                                 :last_name => archived_last_name)
                if success
                  puts "User was successfully deactivated and renamed to #{unique_login}. The original login may now be reused."
                else
                  puts 'There was a problem saving the user with new information. Exiting...'
                  puts user.errors.full_messages.join("\n")
                end
              else
                puts 'Deactivating the user failed. Exiting...'
                puts user.errors.full_messages.join("\n")
              end
            end
          else
            puts "Unable to find user with #{args.login}.  Exiting..."
          end
        rescue => e
          puts "There was a system error: #{e.message}"
          puts e.backtrace.join("\n")
        ensure
          puts "Task complete."
        end
      else
        if response.upcase != 'Y'
          puts "You did not enter 'Y', so the user was left unchanged."
        else
          puts "You did not include a login, so no deletion was possible."
        end
      end
    end

  end

end

