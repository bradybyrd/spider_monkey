namespace :app do

  namespace :scheduled do

    desc "Finds created requests with auto_start true and first plans then starts them"
    task :start_automatic_requests => :environment do
      started_count = 0
      errors = []
      # find requests that are auto_start enabled, just created, whose planned at is less than the current time
      requests = Request.active.where(:auto_start => true).where(:aasm_state => 'planned').where('requests.scheduled_at <= ?', Time.zone.now)
      if requests.any?
        print "Starting #{requests.count} requests: "
        requests.each do |r|
          begin
            # now start it
            r.start!
            # if all goes well increment the counter
            started_count += 1
            # show an indicator on the command prompt
            print "s"
          rescue => e
            print "e"
            errors << e
          end
        end
        puts "\n"
        puts "Successfully #{started_count} requests out of #{requests.length } with #{ errors.length } errors."
        unless errors.blank?
          puts "-------------------------------------"
          puts "Errors encountered: "
          errors.each_with_index do |e, index|
            puts "#{index.to_s}.#{e.message}"
            puts e.backtrace.join("\n")
            puts "-------------------------------------"
          end
        end
      else
        puts "No requests found that could be automatically started."
      end
    end
  end
end
