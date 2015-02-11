# March 23, 2010 
# Implementing request has many applications
# http://www.pivotaltracker.com/story/show/11326319

# rake sr:multiple_apps:apps_requests_data

desc "Add data in table `apps_requests` from `requests`"
namespace :sr do
  namespace :multiple_apps do
    task :apps_requests_data => :environment do
      AppsRequest.destroy_all
      Request.all.each do |request|
        puts "Checking Request - #{request.number}:#{request.name}"
        if request.app_id.present?
          request.update_attributes(:app_ids => [request.app_id])
          request.steps.each do |step|
            if step.component_id.present?
              # app_id is added in steps table help to know to which app step component belongs to as there are now multiple apps used in request
              puts " Assigning app_id to step"
              puts "  #{step.position}:#{step.name}"
              Step.connection.execute("UPDATE steps SET app_id = #{request.app_id} WHERE id = #{step.id} AND app_id IS NULL")
            end
          end
        end
      end
    end
  end
end