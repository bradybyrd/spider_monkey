class CreateEnvDatesForRequests26 < ActiveRecord::Migration
  def up
	   
    requests = Request.find_by_sql("SELECT * FROM requests INNER JOIN apps_requests ON apps_requests.request_id = requests.id INNER JOIN environments ON environments.id = requests.environment_id INNER JOIN plan_members ON plan_members.id = requests.plan_member_id")

    requests.each do |request|
      request.app_ids.each do |appid|
       if request.plan_member.present?
         p = PlanEnvAppDate.where("app_id = ? and environment_id = ? and plan_id = ?", appid, request.environment_id, request.plan_member.plan_id).all
         PlanEnvAppDate.create(:app_id=> appid, :environment_id => request.environment_id, :plan_id => request.plan_member.plan_id, :plan_template_id => '1' , :created_at => Time.now, :created_by => request.owner_id) if (p.size == 0) 
       end 
      end
    end    
        
  end

  def down

  end
end
