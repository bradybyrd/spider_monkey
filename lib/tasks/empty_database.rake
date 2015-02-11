# rake db:create, rake db:drop do not work with OracleAdapter so these custom rakes are written

desc "Delete all the database tables"

namespace :db do
  task :drop_database => :environment do
    puts "Dropping tables"
    Rake::Task["db:drop_tables"].invoke
    puts " Dropping sequences"
    Rake::Task["db:drop_sequences"].invoke
  end
end

namespace :db do
  task :drop_tables => :environment do
    ActiveRecord::Base.connection.tables.each do |table_name|
      status = ActiveRecord::Base.connection.execute "DROP TABLE #{table_name}" rescue 'error'
      seq_status = ActiveRecord::Base.connection.execute "DROP SEQUENCE #{table_name}_seq" rescue 'error'
      if status == 'error'
        puts "Failed to drop - #{table_name}"
      else
        puts "Dropped - #{table_name}"
      end
      if seq_status == 'error'
        seq_status = ActiveRecord::Base.connection.execute "DROP SEQUENCE #{table_name.upcase}_SEQ" rescue 'error'
        if seq_status == 'error'
          puts "Dropped - SEQUENCE #{table_name}_seq"
        else
          puts "Failed to drop - SEQUENCE #{table_name}_seq"
        end
      else
        puts "Dropped - SEQUENCE #{table_name}_seq"
      end

    end
    # New tables/views added by Brady
    ActiveRecord::Base.connection.execute "drop table SCHEMA_MIGRATIONS" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITIES" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITIES_LIFECYCLE_MEMBERS" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITIES_VIEW" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITY_ATTRIBUTES" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITY_ATTRIBUTE_VALUES" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITY_CREATION_ATTRIBUTES" rescue 'error'
    ActiveRecord::Base.connection.execute "drop table ACTIVITY_CATEGORIES" rescue 'error'

    puts " Dropping sequences"
    if (MsSQLAdapter)
      puts "MSSQL server already dropped sequence"
    else
      query_string = OracleAdapter ? "SELECT SEQUENCE_NAME FROM user_sequences" :  "SELECT  c.relname AS SEQUENCE_NAME FROM pg_class c WHERE (c.relkind = 'S')"
      (ActiveRecord::Base.connection.select_values query_string).each do |seq|
      seq_status = ActiveRecord::Base.connection.execute "DROP SEQUENCE #{seq}" rescue 'error'
          if seq_status == 'error'
            puts "Failed to drop - #{seq}"
          else
            puts "Dropped - #{seq}"
          end
      end
    end
  end
end

  # rake db:drop_sequences is not required if this has already been executed on Oracle db
  # because sequences tables are created during initial database setup
namespace :db do
  task :drop_sequences => :environment do
    sequences  = %W{
      bladelogic_script_argument_seq
      capistrano_script_argument_seq
      project_templates_seq
      projects_seq
      project_attributes_seq
      project_tabs_seq
      project_tab_attributes_seq
      project_attribute_values_seq
      project_notes_seq
      project_deliverables_seq
      project_phases_seq
      project_phase_times_seq
      project_index_columns_seq
      standard_operating_procedu_seq
      temporary_budget_line_item_seq
      package_template_component_seq
      aca_seq
      parent_activities_seq
      activity_creation_attribut_seq
    }.each do |sequence|
      begin
        ActiveRecord::Base.connection.execute "DROP SEQUENCE #{sequence}"
        puts "DROP SEQUENCE #{sequence}"
      rescue Exception => e
        puts "#{sequence} cannot be dropped: #{e.message}"
      end
    end

    # New tables/views added by Brady.
    ActiveRecord::Base.connection.execute "drop sequence ACTIVITY_PHASE_DATES_SEQ" rescue 'error'
    ActiveRecord::Base.connection.execute "drop sequence ACTIVITY_PHASE_TIMES_SEQ" rescue 'error'
    ActiveRecord::Base.connection.execute "drop sequence ACTIVITY_TEMPLATES_SEQ" rescue 'error'
    ActiveRecord::Base.connection.execute "drop view AGGREGATE_BLIS_VIEW" rescue 'error'
    ActiveRecord::Base.connection.execute "drop view AGGREGATE_FINANCIALS_VIEW" rescue 'error'
    ActiveRecord::Base.connection.execute "drop sequence CONTAINERS_ACTIVITIES_SEQ" rescue 'error'
    ActiveRecord::Base.connection.execute "drop view CONTAINERS_VIEW" rescue 'error'
    ActiveRecord::Base.connection.execute "drop view FINANCIALS_VIEW" rescue 'error'

    file_base_path = File.join(Rails.root, 'data', 'fixtures')
    files_array = Dir.glob(File.join(file_base_path, '*.{yml}'))
    files_array.each do |fixture_file|
      table_name = File.basename(fixture_file.strip, ".yml")
      begin
        ActiveRecord::Base.connection.execute "DROP SEQUENCE #{table_name}_seq"
        puts "DROP SEQUENCE #{table_name}_seq"
      rescue Exception => e
        puts "#{table_name}_seq cannot be dropped: #{e.message}"
      end
    end
  end

end
