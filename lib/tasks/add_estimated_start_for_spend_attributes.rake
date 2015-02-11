namespace :sp do
  task :add_estimated_start_for_spend_attributes => :environment do
  
    ActivityAttribute.create(:name => "Estimated Start for Spend", :required => 0, 
        :input_type => "date", :attribute_values => ["User entered"], :created_at => Time.now, :from_system => 0,
        :type => "ActivityStaticAttribute", :field => "estimated_start_for_spend")
      
      activity_attribute = ActivityAttribute.find_by_name("Estimated Start for Spend")
      activity_tab_project = ActivityTab.find_by_name_and_activity_category_id("Current Status",31)
      activity_tab_service = ActivityTab.find_by_name_and_activity_category_id("Current Status",32)
      
      #update type
      activity_attribute.update_attribute(:type, "ActivityStaticAttribute")
      
      #change position attributes for Project category
      activity_creation_attributes = ActivityCreationAttribute.find(:all, :conditions => "activity_category_id = 31 AND position > 6")
      activity_creation_attributes.each do |activity_creation_attribute|
          activity_creation_attribute.update_attribute(:position, activity_creation_attribute.position + 1)
      end
      
      #change position attributes for Service category
      activity_creation_attributes = ActivityCreationAttribute.find(:all, :conditions => "activity_category_id = 32 AND position > 15")
      activity_creation_attributes.each do |activity_creation_attribute|
          activity_creation_attribute.update_attribute(:position, activity_creation_attribute.position + 1)
      end
      
      #change position tab_attributes for Project category
      activity_tab_attributes = ActivityTabAttribute.find(:all, :conditions => "activity_tab_id = #{activity_tab_project.id} AND position > 4") rescue []
      activity_tab_attributes.each do |activity_tab_attribute|
          activity_tab_attribute.update_attribute(:position, activity_tab_attribute.position + 1)
      end
      
      #change position tab_attributes for Service category
      activity_tab_attributes = ActivityTabAttribute.find(:all, :conditions => "activity_tab_id = #{activity_tab_service.id} AND position > 1") rescue []
      activity_tab_attributes.each do |activity_tab_attribute|
          activity_tab_attribute.update_attribute(:position, activity_tab_attribute.position + 1)
      end
      
      #add Estimated Start for Spend to activity_creation_attributes
      ActivityCreationAttribute.create(:activity_category_id => 31, 
        :activity_attribute_id => activity_attribute.id, :created_at => Time.now)
      ActivityCreationAttribute.create(:activity_category_id => 32, 
        :activity_attribute_id => activity_attribute.id, :created_at => Time.now )
      
      ActivityTabAttribute.create(:activity_tab_id => activity_tab_project.id, :activity_attribute_id => activity_attribute.id) if activity_tab_project
      ActivityTabAttribute.create(:activity_tab_id => activity_tab_service.id, :activity_attribute_id => activity_attribute.id) if activity_tab_service
      
      #update position 
      activity_creation_attribute = ActivityCreationAttribute.find(:first, :conditions => "activity_category_id = 31 AND activity_attribute_id = #{activity_attribute.id}")
      activity_creation_attribute.update_attribute(:position, 7)
      
      activity_creation_attribute = ActivityCreationAttribute.find(:first, :conditions => "activity_category_id = 32 AND activity_attribute_id = #{activity_attribute.id}")
      activity_creation_attribute.update_attribute(:position, 16)
      
      if activity_tab_project
        activity_tab_attribute = ActivityTabAttribute.find(:first, :conditions => "activity_tab_id = #{activity_tab_project.id} AND activity_attribute_id = #{activity_attribute.id}")
        activity_tab_attribute.update_attribute(:position, 5)
      end
    
      if activity_tab_service
        activity_tab_attribute = ActivityTabAttribute.find(:first, :conditions => "activity_tab_id = #{activity_tab_service.id} AND activity_attribute_id = #{activity_attribute.id}")
        activity_tab_attribute.update_attribute(:position, 2)
      end
  
  end
end