# September 09, 2011

# Setting proper values for columns present in change_requests table, where previously unique identifier was coming

# rake sr:service_now:rewrite_changer_request_attribute_values

desc "Set proper values for columns of `change_requests` table"
namespace :sr do
  namespace :service_now do
    task :rewrite_changer_request_attribute_values => :environment do
      ChangeRequest.all.each do |cr|
        puts "rewriting column values for change request #{cr.id}"
        attrs = cr.set_attribute_values({:u_cc_environment => cr.u_cc_environment, :assignment_group => cr.assignment_group, :u_pmo_project_id => cr.u_pmo_project_id})
        if attrs[:u_cc_environment] != cr.u_cc_environment && attrs[:assignment_group] != cr.assignment_group && attrs[:u_pmo_project_id] != cr.u_pmo_project_id
          cr.update_attributes(attrs)
        end  
      end
    end
  end
end