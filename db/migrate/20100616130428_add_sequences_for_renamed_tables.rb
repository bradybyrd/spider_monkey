################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddSequencesForRenamedTables < ActiveRecord::Migration
  
  # rescue '' is put because at the moment I am not for which tables Oracle creates
  # sequence automatically. For some tables it does but not for all
  # My thinking is that it doesn't do that for tables that are
  # renamed.
  
  def self.up
    if OracleAdapter
      execute("CREATE SEQUENCE application_environments_seq INCREMENT BY 1 START WITH 10000") rescue ''
      execute("CREATE SEQUENCE components_seq INCREMENT BY 1 START WITH 10000") rescue ''
      
      execute("CREATE SEQUENCE installed_components_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE apps_seq INCREMENT BY 1 START WITH 10000") rescue ''
      
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE environments_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE properties_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE property_values_seq INCREMENT BY 1 START WITH 10000") rescue ''     
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE component_properties_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE property_tasks_seq INCREMENT BY 1 START WITH 10000") rescue ''
      
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activity_logs_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE assets_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE lifecycle_templates_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE lifecycles_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE groups_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activities_seq INCREMENT BY 1 START WITH 10000") rescue ''
      
      %w{project_attribute_values
        project_attributes
        project_creation_attributes
        project_deliverables
        project_index_columns
        project_notes
        project_phase_times
        project_phases
        project_tab_attributes
        project_templates
        project_tabs}.each do |table|
          ActiveRecord::Base.connection.execute("CREATE SEQUENCE #{table.sub('project', 'activity')}_seq INCREMENT BY 1 START WITH 10000") rescue ''
        end
        
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE lifecycle_members_activities_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE containers_activities_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activities_containers_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activities_lifecycle_members_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activity_categories_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE parent_activities_seq INCREMENT BY 1 START WITH 10000") rescue ''
      ActiveRecord::Base.connection.execute("CREATE SEQUENCE activity_phase_dates_seq INCREMENT BY 1 START WITH 10000") rescue ''

    end
  end

  def self.down
    # Irreversible
    # TODO - I need to find out which tables are missed for which sequences are not created
    # Need to find out that
  end
end
