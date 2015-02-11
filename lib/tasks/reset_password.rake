desc "Reset Account Password"

def ask(message)
  puts "#{message}:"
  val = STDIN.gets.chomp
  if val.nil? || val.strip.empty?
    return ask(message)
  else
    return val
  end
end

def ask_for_password(message)
  val = ask(message) {|q| q.echo = false}
  if val.nil? || val.strip.empty?
    return ask_for_password(message)
  else
    return val
  end
end

def render_errors(obj)
  index = 0
  obj.errors.keys.each do |key|
    index += 1
    puts "#{index}. #{key} - #{obj.errors[key]}"
  end
end

namespace :app do
  task :reset_password => :environment do
    login = ask("Enter Login")
    user = User.find_by_login(login)
    if user
      password = ask_for_password("Enter Password")
      password_confirmation = ask_for_password("Confirm Password")
      user.password = password
      user.password_confirmation = password_confirmation
      ## Callback skipped because Notifier cannot send email with delay from task
      ## TODO that it probably should reverted but without torquebox
      user.class.skip_callback(:update, :after, :send_notification_email)

      if user.save
        puts "Password for Login #{login} is reset successfully."
      else
        render_errors(user)
      end
    else
      puts "No such admin user found in database"
    end
  end
end