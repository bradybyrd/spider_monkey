namespace :app do
  namespace :lists do
    
    task :add_release_content_item_status => :environment do
      list = List.find_or_create_by_name("ReleaseContentItemState")
      list.is_text = true
      list.save
      puts "#{list.name} is sucesssfully added to lists"
    end
    
    task :remove_release_content_item_status => :environment do
      list = List.find_or_create_by_name("ReleaseContentItemState")
      list.destroy if list
      puts "#{list.name} is sucesssfully removed from lists"
    end
  end
end


  