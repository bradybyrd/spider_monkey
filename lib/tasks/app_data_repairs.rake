namespace :app do

  namespace :data_repairs do

    desc "Adds environment group name to environment names before migration deletes groups to avoid identical environments"
    task :add_environment_group_names_to_environment_names => :environment do
      renamed_count = 0
      environments = Environment.find(:all)
      environments.each do |e|
      # now we have to use SQL because a lot of these models are gone
        results = ActiveRecord::Base.connection.execute("SELECT environment_groups.name, grouped_environments.environment_id FROM grouped_environments INNER JOIN environment_groups ON grouped_environments.environment_group_id = environment_groups.id WHERE grouped_environments.environment_id = #{e.id}")
        if results.is_a?(Array)
          results.each do |result|
            group_name = result["name"]
            unless group_name.blank? || e.name.include?("#{group_name}: ")
              e.update_attribute(:name, "#{group_name}: #{e.name}")
              renamed_count += 1
              print "."
            end
          end
        end

      end
      puts " Renamed #{renamed_count} environments."
    end

    desc "Corrects a typo in the data for plan template type continuous integrations"
    task :fix_continuous_integrations => :environment do
      puts "-------------- Correcting typo: \"continuos_integrations\" -> \"continuous_integrations\" --------------"
      my_plans = PlanTemplate.find(:all, :conditions => ("template_type LIKE '%continuos_integration%'"))
      count = 0
      my_plans.each do |lt|
        if lt.update_attribute(:template_type,'continuous_integration')
          print "."
        count += 1
        else
          puts "Problem saving plan template " + lt.id.to_s
        end
      end
      puts "Updated #{count} plan templates"
    end

    desc "Multi-item plan cleanup: removing superfluous plan members not related to requests"
    task :stage_dates_to_members => :environment do
      puts "This will delete plan members not related to requests. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        members_to_delete = PlanMember.find(:all).select { |m| m.request == nil}
        deleted_count = members_to_delete.count
        members_to_delete.each { |m| m.destroy }
        puts "Removed #{deleted_count} legacy members unrelated to requests."
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end

    desc "Adjust duplicate plan stage names with the same plan template"
    task :rename_duplicate_plan_stages => :environment do
      puts "This will sequentially rename plan stages with duplicate names and the same plan template. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        begin
        # brute force approach for maximum database compatibility
          stages = PlanStage.find(:all, :order => ['plan_template_id, name, position'] )
          renamed_count = 0
          previous_plan_template_id = nil
          previous_name = ''
          previous_id = nil
          increment = 1
          stages.each do |stage|
            if stage.plan_template_id == previous_plan_template_id && stage.name == previous_name
              stage.update_attribute(:name, "#{stage.name} [duplicate #{increment} of stage #{previous_id}]")
              renamed_count += 1
              increment += 1
              print "."
            else
            # if we have found a duplicate, then hold on to the last values, otherwise store the new ones
            previous_plan_template_id = stage.plan_template_id
            previous_name = stage.name
            previous_id = stage.id
            increment = 1
            end
          end
        rescue => e
          puts " There was an error: " + e.message
        else
          puts " Renaming complete. Processed #{stages.count} stages and renamed #{renamed_count} duplicates."
        end
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end

    desc "Adjust deleted plan names so they do not reserve unique name"
    task :rename_deleted_plans_uniquely => :environment do
      puts "This will sequentially rename plans that have been deleted so new plans may be created with the same name. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        begin
          deleted = Plan.find(:all, :conditions => {:aasm_state => 'deleted'})
          renamed_count = 0
          deleted.each do |plan|
            unless plan.name.include?('[deleted ')
              plan.update_attribute(:name, "#{plan.name} [deleted #{Time.now.to_s(:db)}]")
              renamed_count += 1
              print "."
            end
          end
        rescue => e
          puts "There was an error: " + e.message
        else
          puts "Renaming complete. Processed #{deleted.count} deleted plans and renamed #{renamed_count}."
        end
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end

    desc "Repair positions on plan members"
    task :repair_plan_member_positions => :environment do
      puts "This will sequentially renumber plan members after sorting them by position. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        print "Processing..."
        begin
          lms = PlanMember.find(:all, :order => 'plan_members.plan_id, plan_members.plan_stage_id, plan_members.run_id, plan_members.position')
          counter = 1
          old_run_id = nil
          old_plan_stage_id = nil
          old_plan_id = nil
          lms.each do |lm|
            # reset the counter on new plan, stage, or run
            if old_plan_id != lm.plan_id || old_plan_stage_id != lm.plan_stage_id || old_run_id != lm.run_id
              counter = 1 
              old_run_id = lm.run_id
              old_plan_stage_id = lm.plan_stage_id
              old_plan_id = lm.plan_id
            end
            lm.update_attribute(:position, counter)
            counter += 1
            print "."
          end
        rescue => e
          puts "There was an error: " + e.message
        else
          puts "Reordering complete."
        end
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end

    desc "Repair legacy request list preferences"
    task :repair_legacy_request_list_preferences => :environment do
      begin
        prefs = Preference.all
        if prefs
          counter = 0
          user_ids_to_reset = []
          print "Processing preferences..."
          # first fix the ones that were just renamed so we don't lose position info
          prefs.each do |pref|
            new_text = case pref.text
            when 'request_created_at_td' then 'request_created_td'
            when 'request_environment_td' then 'request_env_td'
            when 'request_scheduled_at_td' then 'request_scheduled_td'
            else nil
            end
            if new_text
              pref.update_attribute(:text, new_text)
              print "."
            counter += 1
            end
            user_ids_to_reset << pref.user_id
          end

          # now reset each of the users to get the new ones, this routine is like visiting the preferences screen
          # and will delete invalid columns and rename any others that have changed.
          users = User.find(user_ids_to_reset.uniq.sort) unless user_ids_to_reset.blank?
          if users
            users.each do |user|
              Preference.request_list_for(user)
            end
          end
        end
      rescue => e
        puts "There was an error: " + e.message
      else
        puts "Renaming legacy preferences complete. Renamed #{counter} preference(s) and reset the menu preferences of #{users.try(:count) || 0} user(s)."
      end
    end

    desc "Deleted invalid step holders with null step, request, or change requests"
    task :delete_invalid_step_holders => :environment do
      puts "This will find and delete step holders with invalid steps, requests, or change requests. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'  
        begin
          print "Processing..."
          deleted_count = 0
          step_holders = StepHolder.all
          step_holders.each do |s|
            if s.step.nil? || s.request.nil? || s.change_request.nil?
              s.destroy
              deleted_count += 1
              print "."
            end
          end      
        rescue => e
          puts "There was an error: " + e.message
        else
          puts " Deleted #{deleted_count} invalid step holders."
        end 
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end
    
    desc "Repair postgres sequences for all tables"
    task :repair_postgres_sequences => :environment do
      puts "This will reset postgres sequences if database operations have left them misalligned with data. Please backup first. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        print "Resequencing..."
        if PostgreSQLAdapter
          begin
            tables = ActiveRecord::Base.connection.tables
            tables.each do |table_name|
              ActiveRecord::Base.connection.reset_pk_sequence!(table_name)
            end
          rescue => e
            puts "There was an error: " + e.message
          else
            puts "Reordering complete. Processed #{tables.length} tables."
          end
        else
          puts 'This database task only works for Postgres. Database unchanged.'
        end
      else
        puts "You did not enter 'Y', so the sequences were left unchanged."
      end
    end
    
  end

  desc "Convert legacy active/inactive to new archive model"
  task :convert_active_to_archive => :environment do
    puts "This will archive models previous marked inactive in the 2.5 soft delete system. Proceed? [y/n]"
    response = $stdin.gets.chomp
    if response.upcase == 'Y'
      puts "\nStarting..."
      begin
      ####################
      ######## CATEGORY
      ###################
      # check that categories is archivable?
        if Category.is_archival?
          # get the inactive categories
          inactive_models = Category.find(:all, :conditions => { :active => false })
          archive_collection(inactive_models, "categories") unless inactive_models.blank?
        else
          puts "\nError: tried to convert Category but it was not archivable. Have the required migrations been run?"
        end
        ####################
        ######## LIST
        ###################
        # check that model is archivable?
        if List.is_archival?
          # get the inactive model
          inactive_models = List.find(:all, :conditions => { :is_active => false })
          archive_collection(inactive_models, "lists") unless inactive_models.blank?
        else
          puts "\nError: tried to convert List but it was not archivable. Have the required migrations been run?"
        end
      rescue => e
        puts "\nThere was an error: " + e.message
      else
        puts "\nConversion complete."
      end
    else
      puts "\nYou did not enter 'Y', so the database was left unchanged."
    end
  end

  private

  def archive_collection( inactive_models, name )
    puts "Converting #{inactive_models.count} #{ name }. (* = success, s = skipped due to new model restrictions)"
    inactive_models.each do |im|
      success = im.archive unless im.archived?
      print (success ? " * " : " s " )
    end
    puts "\nFinished converting #{ name }."
  end

end

