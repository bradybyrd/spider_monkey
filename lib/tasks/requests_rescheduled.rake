desc "Updates activity_logs table with requests entries that were rescheduled"
namespace :sr do
  namespace :activities do
    task :log_rescheduled_entries => :environment do 
      Request.all.each do |request|
        request.audits.each do |audit|
          changes = audit[:changes]
          if changes.keys.include?('rescheduled')
            puts "Request ID: #{request.id}  Audit: #{audit.id} Change: #{audit[:changes]['rescheduled'].inspect}"
            if audit[:changes]['rescheduled']
              if audit[:changes]['rescheduled'][1] == true
                puts "Request ID: #{request.id}  Audit: #{audit.id} is an **rescheduled event**"
                activity_log = ActivityLog.new
                activity_log.user_id = audit.user_id
                activity_log.request_id = audit.auditable_id
                activity_log.activity = 'Rescheduled'
                activity_log.save
                puts "Rescheduled Event logged in activity_logs"
              end
            end
          end
        end
      end
    end
  end
end