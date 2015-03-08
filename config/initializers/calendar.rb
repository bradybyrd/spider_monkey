module Calendar
  FIELDS = [  
              ['Status', 'aasm.current_state'],
              ['Project', 'project_name'],
              ['Process', 'business_process_name'],
              ['Application', 'app_name'],
              ['Environment', 'environment_name'],
              ['Package content tags', 'package_content_tags'],
              ['Plan', 'lifecyle_name'],
              ['Server', 'associated_servers'],
              ['Requestor', 'requestor_name_for_index'],
              ['Owner', 'owner_name'],
              ['Release tag', 'release_name'],
              ['Estimate', 'estimate'],
              ['Rescheduled', 'rescheduled'],
              ['Team', 'team']
         ] # unless defined?(Calendar::FIELDS)
end