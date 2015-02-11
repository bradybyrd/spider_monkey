desc "Updates activity_logs table with requests entries that were rescheduled"
namespace :sr do
  namespace :requests do
    task :set_cancelled_at => :environment do 
      Request.all.each do |request|
        if request.aasm_state == 'cancelled'
          cancelled_activity = ActivityLog.find(:last, :conditions => {:request_id => request.id, :activity => 'Cancelled'})
          unless cancelled_activity.nil?
            puts "Updating cancelled_at attribute of Request: #{request.id}"
            request.update_attribute(:cancelled_at, cancelled_activity.created_at)
          end
        end
      end
    end
  end
end