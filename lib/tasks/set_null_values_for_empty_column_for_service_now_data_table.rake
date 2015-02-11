# August 20, 2011

# Setting NULL values for name column for records present in service_now_data table

# rake sr:service_now:change_blank_attributes_to_nil

desc "Set NULL for name column of `service_now_data` table"
namespace :sr do
  namespace :service_now do
    task :change_blank_attributes_to_nil => :environment do
      ServiceNowData.all.each do |servie_now_data|
        if servie_now_data.name.blank?
          puts "Setting NULL value for #{servie_now_data.id} column"
          servie_now_data.update_attribute("name", nil)
        end
      end
    end
  end
end