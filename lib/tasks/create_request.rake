desc "Creates request from inputs provided from command prompt"

def ask_for_password(message)
  val = ask(message) {|q| q.echo = false}
  if val.nil? || val.strip.empty?
    return ask_for_password(message)
  else
    return val
  end
end

def ask(message)
  puts "#{message}:"
  val = STDIN.gets.chomp
  if val.nil? || val.strip.empty?
    return ask(message)
  else
    return val
  end
end

def render_errors(obj)
  index = 0
  obj.errors.each_full do |msg|
    index += 1
    puts "#{index}. #{msg}"
  end
end


namespace :sr do
  task :create_request => :environment do
    puts "Login - Provide your login and password to create request"
    login = ask("Enter Login") if false
    password = ask_for_password("Enter Password") if false
    current_user = User.authenticate('admin', 'testtest1')
    if current_user # Login details correct

      # Rake is not required to be interactive
      request_name = ENV['RequestName']
      environment = ENV['Env']
      template_name = ENV['Template']

      errors = []

      if environment
        env = Environment.find_by_name(environment.strip) rescue "#{environment.strip} is invalid environment name."
        errors << "#{environment} is invalid environment name." if env.nil? or env.is_a?(String)
      end

      if template_name
        template = RequestTemplate.find_by_name(template_name.strip) rescue "#{template_name} is invalid template name"
        errors << "#{template_name} is invalid template name" if template.nil? or template.is_a?(String)
      end

      if errors.empty? # No errors in input

        if template.nil? # Creating request using request template
          puts "Initializing new request..."
          request = Request.new
        else
          puts "Initializing request using #{template.name} template"
          request = template.create_request_for(current_user, {})
        end
        request.requestor_id = current_user.id
        request.owner_id = current_user.id
        request.deployment_coordinator_id = current_user.id
        request.name = request_name unless request_name.nil?
        request.environment_id = env.id unless env.nil?
        request.rescheduled = false # Rescheduled should be false for requests created from templates
        request.turn_off_steps # Turn OFF steps whose components are not selected

        if request.save
          puts "Request was successfully created"
          puts "Request ID is #{request.number}"
        else
          render_errors(request)
        end

      else
        errors << "Request could not created due to following errors."
        errors.reverse.each do |e|
          puts e
        end
      end

    else
      puts 'Invalid Login/Password. Please try again.'
    end
  end
end