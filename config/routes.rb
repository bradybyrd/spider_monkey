Brpm::Application.routes.draw do

  begin
    devise_for :users, :path_names => { :sign_in => 'login', :sign_out => 'logout' }, :controllers => { :sessions => 'sessions', :registrations => 'users' }
  rescue Exception => e
    puts "Ignore devise error: #{e.message}"
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'dashboard#self_services'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  namespace :v1 do
    resources :plan_stages

    ### Manish, 2012-05-31, Rest API must not change.
    ### CF: We should discuss this for 2.6 --> we can spoof the old and provide deprecation but field names, etc all changed
    #resources :plan_templates, :as => :plan_templates
    #resources :plans, :as => :plans
    resources :activity_logs
    resources :apps
    resource  :application_packages
    resources :business_processes
    resources :categories
    resources :components
    resources :constraints
    resources :environments
    resources :environment_types
    resources :groups
    resources :installed_components
    resources :job_runs
    resources :lists
    resources :list_items
    resources :notification_templates
    resources :packages
    resources :package_contents
    resources :package_instances
    resources :phases
    resources :plan_routes
    resources :plan_stage_instances
    resources :plan_templates
    resources :plans
    resources :properties
    resources :procedures
    resources :project_servers
    resources :references
    resources :releases
    resources :request_templates
    resources :requests
    resources :roles
    resources :routes
    resources :route_gates
    resources :runs
    resources :scheduled_jobs
    resources :scripts
    resources :servers
    resources :server_groups
    resources :steps do
      get :notify, on: :member
    end
    resources :teams
    resources :tickets
    resources :users
    resources :version_tags
    resources :work_tasks

    namespace :deployment_window do
      resources :series, only: [:index, :show, :create, :update, :destroy]
      resources :events, only: [:show, :update]
    end
  end

  match '/' => 'dashboard#self_services'
  match 'dashboard' => 'dashboard#index', :as => :dashboard
  match '/dashboard/steps_for_request_ajax' => 'dashboard#steps_for_request_ajax', :as => :steps_for_request_ajax, :via => :get
  match '/calendars/dashboard/steps_for_request_ajax' => 'dashboard#steps_for_request_ajax', :as => :steps_for_request_ajax, :via => :get
  match '/request_dashboard' => 'dashboard#request_dashboard', :as => :request_dashboard, :show_all => '1'
  match '/promotion_requests' => 'dashboard#promotions', :as => :promotion_requests
  match '/my-dashboard' => 'dashboard#self_services', :as => :my_dashboard
  match '/recent-requests' => 'dashboard#recent_requests', :as => :recent_requests
  match '/recent_activities' => 'dashboard#recent_activities', :as => :recent_activities
  match '/my_applications' => 'dashboard#my_applications', :as => :my_applications
  match '/my_environments' => 'dashboard#my_environments', :as => :my_environments
  match '/my_servers' => 'dashboard#my_servers', :as => :my_servers

  scope 'calendars' do
    match '/upcoming-requests' => 'calendars#upcoming_requests', :as => :upcoming_requests
    match 'month/:beginning_of_calendar' => 'calendars#month', :as => :calendar_month
    match 'month' => 'calendars#month', :as => :calendar_months
    match 'dashboard/month/:beginning_of_calendar' => 'calendars#month', :as => :calendar_dashboard_month, :for_dashboard => true
    match 'dashboard/month' => 'calendars#month', :as => :calendar_dashboard_months, :for_dashboard => true
    match 'day/:beginning_of_calendar' => 'calendars#day', :as => :calendar_day
    match 'day' => 'calendars#day', :as => :calendar_days
    match 'dashboard/day/:beginning_of_calendar' => 'calendars#day', :as => :calendar_dashboard_day, :for_dashboard => true
    match 'dashboard/day' => 'calendars#day', :as => :calendar_dashboard_days, :for_dashboard => true
    match 'week/:beginning_of_calendar' => 'calendars#week', :as => :calendar_week
    match 'week' => 'calendars#week', :as => :calendar_weeks
    match 'dashboard/week/:beginning_of_calendar' => 'calendars#week', :as => :calendar_dashboard_week, :for_dashboard => true
    match 'dashboard/week' => 'calendars#week', :as => :calendar_dashboard_weeks, :for_dashboard => true
    match 'rolling/:beginning_of_calendar' => 'calendars#rolling', :as => :calendar_rolling
    match 'rolling' => 'calendars#rolling', :as => :calendar_rollings
    match 'dashboard/rolling/:beginning_of_calendar' => 'calendars#rolling', :as => :calendar_dashboard_rolling, :for_dashboard => true
    match 'dashboard/rolling' => 'calendars#rolling', :as => :calendar_dashboard_rollings, :for_dashboard => true
  end

  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
  match '/cas_logout' => 'sessions#cas_signout', :as => :cas_logout
  match '/relogin' => 'sessions#relogin', :as => :relogin
  match '/profile' => 'users#profile', :as => :profile
  match '/forgot-password' => 'users#forgot_password', :as => :forgot_password
  match '/reset-password' => 'users#reset_password', :as => :reset_password, :via => :put
  match 'forgot-userid' => 'users#forgot_userid', :as => :forgot_userid
  match 'get_security_question' => 'users#get_security_question', :as => :get_security_question
  match '/calendar-preferences' => 'users#calendar_preferences', :as => :user_calendar_preferences
  match '/request-list-preferences' => 'users#request_list_preferences', :as => :user_request_list_preferences, :via => [:get, :post]
  match '/request-list-preferences/reset' => 'users#reset_request_preferences', :as => :reset_request_list_preferences, :via => :get
  match '/step-list-preferences' => 'users#step_list_preferences', :as => :user_step_list_preferences, :via => [:get, :post]
  match '/step-list-preferences/reset' => 'users#reset_step_preferences', :as => :reset_step_list_preferences, :via => :get
  match 'update_profile' => 'users#update_profile', :as => :update_profile
  match 'settings' => 'account#settings', :as => :settings
  match 'statistics' => 'account#statistics', :as => :statistics
  match 'request_modification' => 'requests#request_modification', :as => :request_modification
  match '/settings/bulk_destroy' => 'requests#bulk_destroy', :as => :bulk_destroy
  match 'modify_request' => 'requests#modify_request', :as => :modify_request
  match 'settings_update' => 'account#update_settings', :as => :settings_update
  match 'automation_monitor' => 'account#automation_monitor', :as => :automation_monitor
  match 'quick_automation' => 'account#quick_automation', :as => :quick_automation
  match 'settings/system' => 'account#system', :as => :settings_system
  match '/settings/calendar-preferences' => 'account#calendar_preferences', :as => :calendar_preferences, :via => :get

  scope 'REST' do
    match 'ssh_scripts.xml' => 'rest#ssh_scripts', :as => :ssh_scripts, :method => :get
    match 'list_servers.xml' => 'rest#list_servers', :as => :list_servers, :method => :get
    match 'running_steps.xml' => 'rest#running_steps', :as => :running_steps, :method => :get
    match '/steps/:id/:request_id/callback.xml' => 'rest#step_callback', :as => :step_callback, :method => :get
    match '/requests/:request_id/start_request' => 'rest#start_request', :as => :start_request, :method => :get
    match 'properties_inspector.xml' => 'rest#properties_inspector', :as => :properties_insepctor, :method => :get
    match '/requests/create_request_from_template' => 'rest#create_request_from_template', :as => :create_request_from_template, :method => :get
    match '/requests/create_request_xml' => 'rest#create_request_xml', :as => :create_request_xml, :method => :post
    match '/requests/:request_id/update_state' => 'rest#update_state', :as => :update_state, :method => :get
    match '/steps/:step_id/update_step_state' => 'rest#update_step_state', :as => :update_step_state, :method => :get
    match '/requests/:request_id/change_component' => 'rest#change_component', :as => :change_component, :method => :get
    match '/requests/:request_id/add_step' => 'rest#add_step', :as => :add_step, :method => :get
    match '/requests/:request_id/get_request.:format' => 'rest#get_request', :as => :get_request, :method => :get
    match '/requests/:request_id/request_status' => 'rest#request_status', :as => :request_status, :method => :get
    match '/scripts/get_template_scripts.:format' => 'rest#get_template_scripts', :as => :get_template_scripts, :method => :get
    match '/scripts/get_script.:format' => 'rest#get_script', :as => :get_script, :method => :get

  end

  resources :job_runs
  resources :automation_queue_data do
    collection do
      get :administration
    end
  end


  resources :uploads
  scope 'properties' do
    match '/:id/edit_values' => 'properties#edit_values', :as => :properties_edit_values, :method => :get
  end
  match '/environments_of_app' => 'environments#environments_of_app', :as => :environments_of_app

  scope 'environment' do
    resources :properties do
      collection do
        put :reorder
      end

      member do
        put :deactivate
        put :activate
      end
    end

    match 'metadata' => 'environments#metadata', :as => :manage_metadata
    match 'bladelogic' => 'account#bladelogic', :as => :bladelogic
    match 'capistrano' => 'account#capistrano', :as => :capistrano
    match 'hudson' => 'account#hudson', :as => :hudson

    match 'automation_scripts' => 'account#automation_scripts', :as => :automation_scripts
    match 'toggle_script_filter' => 'account#toggle_script_filter', :as => :toggle_script_filter
    resources :environments do
      collection do
        get :update_server_selects
        post :create_default
      end
      member do
        put :deactivate
        put :activate
      end
    end

    resources :components do
      collection do
        get :unused
      end
      member do
        put :deactivate
        put :activate
        delete :remove_unused
      end
    end

    resources :packages do
      resources :references, only: [:new, :create, :edit, :update]
      resources :package_instances, as: :instances, only: [:index, :new, :create]
      collection do
        get :unused
        get :show_picker
      end
      member do
        put :deactivate
        put :activate
        delete :remove_unused
        get :edit_property_values
        post :update_property_values
        put :update_property_values
        get :show_picker
      end
    end

    resources :package_instances, :only => [:edit, :update, :destroy] do
      member do
        put :deactivate
        put :activate
        get :add_references
        put :copy_references
        get :edit_property_values
        post :update_property_values
        put :update_property_values
      end
    end

    resources :references, only: [:destroy] do
      resources :property_values, only: [:new, :edit, :create, :destroy, :update]
    end

    resources :instance_references, :only => [:edit, :destroy]  do
      member do
        get :edit_property_values
        post :update_property_values
        put :update_property_values
      end
    end


    resources :servers do
      member do
        put :deactivate
        put :activate
        get :edit_property_values
        post :update_property_values
        put :update_property_values
      end
    end

    resources :server_groups do
      member do
        put :deactivate
        put :activate
      end
    end

    resources :server_levels, except: [:destroy] do
      resources :server_aspects do
        match :update_environmentsList, :on => :collection
        collection do
          get :environment_options
        end
        member do
          get :edit_property_values
          put :update_property_values
          get :expand_tree
          get :collapse_tree
        end
      end

      resources :properties,:controller => 'server_level_properties'
      resources :server_level_properties
    end

    resources :server_aspect_groups do
      collection do
        get :server_aspect_options
      end
    end

    resources :bladelogic_scripts do
      collection do
        get :app_env_remote_options
        get :installed_component_remote_options
        get :server_property_options
        get :multiple_application_environment_options
        get :component_options
        get :property_options
      end
      member do
        get :test_run
        get :default_values_from_properties
        get :default_values_from_server_properties
      end
    end


    match 'bladelogic_scripts/:id/script_arguments/:script_argument_id/map_properties' => 'bladelogic_scripts#map_properties_to_argument', :as => :map_properties_to_argument_bladelogic_script
    match 'bladelogic_scripts/:id/script_arguments/:script_argument_id/update_properties' => 'bladelogic_scripts#update_argument_properties', :as => :update_argument_properties_bladelogic_script
    match 'bladelogic_scripts/:id/script_arguments/:script_argument_id/update_server_properties' => 'bladelogic_scripts#update_argument_server_properties', :as => :update_argument_server_properties_bladelogic_script

    # resources :capistrano_scripts do
    #   collection do
    #     get :app_env_remote_options
    #     get :installed_component_remote_options
    #     get :server_property_options
    #     get :build_script_list
    #     get :multiple_application_environment_options
    #     get :component_options
    #     get :property_options
    #   end
    #   member do
    #     get :test_run
    #     get :default_values_from_properties
    #     get :default_values_from_server_properties
    #   end
    # end

    match 'scripts/:id/script_arguments/:script_argument_id/map_properties' => 'scripts#map_properties_to_argument', :as => :map_properties_to_argument_script
    match 'scripts/:id/script_arguments/:script_argument_id/update_properties' => 'scripts#update_argument_properties', :as => :update_argument_properties_script
    match 'scripts/:id/script_arguments/:script_argument_id/update_server_properties' => 'scripts#update_argument_server_properties', :as => :update_argument_server_properties_script

    # resources :hudson_scripts do
    #   collection do
    #     get :app_env_remote_options
    #     get :installed_component_remote_options
    #     get :server_property_options
    #     get :multiple_application_environment_options
    #     get :component_options
    #     get :property_options
    #   end
    #   member do
    #     get :test_run
    #     get :default_values_from_properties
    #     get :default_values_from_server_properties
    #     get :build_job_parameters
    #     get :find_script_template
    #     get :find_jobs
    #   end
    # end

    resources :scripts do
      member do
        get :test_run
        get :default_values_from_properties
        get :default_values_from_server_properties
        put :update_script
        get :build_job_parameters
        get :find_script_template
        get :find_jobs
        put :execute_mapped_resource_automation
        post :update_to_file
        get :update_from_file
        put :archive
        put :unarchive
      end
      collection do
        get :render_integration_header
        get :app_env_remote_options
        get :build_script_list
        get :installed_component_remote_options
        get :package_remote_options
        get :package_instance_remote_options
        get :server_property_options
        get :multiple_application_environment_options
        get :component_options
        get :property_options
        get :import_automation_scripts
        get :render_automation_types
        post :render_automation_form
        get :import_local_scripts_list
        get :import_local_scripts_preview
        get :update_resource_automation_parameters
        post :execute_resource_automation
        get :target_argument_to_load
        post :get_tree_elements
        post :get_table_elements
        get :download_files
        post :initialize_arguments
        post :import_local_scripts
      end
    end

    scope 'scripts' do
      match '/import' => 'scripts#import', :as => :import_script, :method => :get
      match '/import_selected' => 'scripts#import_selected', :as => :import_selected, :method => :get
      match '/import_scripts_list' => 'scripts#import_scripts_list', :as => :import_scripts_list, :method => :get
      match '/import_local_scripts' => 'scripts#import_local_scripts', :as => :import_local_scripts, :method => :post
      match '/:id/update_state/:transition' => 'scripts#update_state', :as => :update_state_scripts, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get
    end

    resources :scripted_resources

    scope 'metadata' do
      resources :procedures do
        member do
          get :reorder_steps
          post :add_to_request
          get :get_procedure_step_section
          put :archive
          put :unarchive
          get :load_tab_data
        end
        collection do
          post :new_procedure_template

        end
      end

      resources :environment_types do
        collection do
          put :reorder
        end
        member do
          put :archive
          put :unarchive
        end
      end

      resources :work_tasks do
        collection do
          put :reorder
        end
        member do
          put :archive
          put :unarchive
        end
      end

      resources :phases do
        collection do
          put :reorder
        end
        member do
          delete :destroy_runtime_phase
          put :archive
          put :unarchive
        end
      end

      resources :package_contents do
        collection do
          put :reorder
        end
        member do
          put :archive
          put :unarchive
        end
      end

      resources :activity_phases do
        collection do
          put :reorder
        end
      end

      resources :plan_templates do
        member do
          put :archive
          put :unarchive
        end
        resources :plan_stages do
          collection do
            put :reorder
          end
        end
      end

      resources :categories do
        collection do
          get :associated_event_options
        end
        member do
          put :archive
          put :unarchive
        end
      end

      resources :request_templates do
        member do
          put :archive
          put :unarchive
        end
      end

      resources :releases do
        collection do
          put :reorder
        end
        member do
          put :archive
          put :unarchive
        end
      end

      resources :business_processes do
        member do
          put :archive
          put :unarchive
        end
      end

      resources :processes, :controller => :business_processes do
        member do
          put :archive
          put :unarchive
        end
      end

      resources :version_tags do
        collection do
          get :app_env_remote_options
          get :installed_component_remote_options
          get :component_options
          get :app_component_remote_options
          get :app_env_pick_list
          get :details
        end

        match :bulk_create, :on => :collection

        member do
          put :archive
          put :unarchive
          get :artifact_url
          get :edit_property_values
          post :update_property_values
          put :update_property_values
        end
      end

      resources :tickets do
        member do
          put :archive
          put :unarchive
        end
        collection do
          get :query
          get :resource_automations
          get :filter_arguments
          post :add_selected_external
        end
      end

      resources :lists do
        member do
          put :archive
          put :unarchive
        end
      end

      resources :list_items do
        member do
          put :archive
          put :unarchive
        end
      end

      namespace :deployment_window do
        resources :series, except: [:show] do
          collection do
            get :show_picker
          end
          member do
            get :show_picker
          end
          member do
            put :archive
            put :unarchive
          end
          resources :occurrences
        end

        resources :events do
          member do
            get :popup
            get :edit_series
            put :suspend
            put :move
            put :request
          end
        end
      end


    end  # ~ scope metadata
  end # ~ scope environment

  match 'download_latest/:branch' => 'app_archive#download_latest', :as => :download_latest
  match 'search' => 'search#index', :as => :search
  match 'status' => 'requests#status', :as => :status
  resource :session
  match 'application_environments/:application_environment_id/installed_components/add_remove_servers' => 'installed_components#add_remove_servers', :as => :add_remove_servers_installed_components
  match 'installed_components/update_servers' => 'installed_components#update_servers', :as => :update_servers_installed_components
  resources :apps do
    collection do
      post :create_default
      get :application_environment_options
      get :application_process_options
      get :installed_component_options
      get :route_options
      get :import_app
      post :import
      post :upload_csv
      get :show_picker
    end
    member do
      put :deactivate
      put :activate
      get :export_application
      post :export
      get :reorder_components
      get :reorder_environments
      get :add_remote_components
      put :create_remote_components
      get :load_env_table
      get :request_template_options
      get :show_picker
    end
    resources :application_environments do
      collection do
        get :add_remove
        put :update_all
      end
    end

    resources :application_components do
      collection do
        get :add_remove
        put :copy_all
        put :update_all
        get :setup_clone_components
        put :clone_components
      end
      member do
        get :edit_property_values
        put :update_property_values
        get :add_component_mapping
        get :resource_automations
        get :filter_arguments
        put :save_mapping
        get :edit_component_mapping
        delete :delete_mapping
      end
    end

    resources :application_packages do
      collection do
        put :update_all
      end
    end

    resources :installed_components
    resources :package_templates do
      member do
        delete :delete_template_item
      end
    end

    # routes are ordered lists of environments associated with an application
    resources :routes do
      member do
        put :archive
        put :unarchive
        post :add_environments
      end
      resources :route_gates, :only => [:update, :destroy]
    end
  end

  resources :steps do
    match :update_components, :on => :collection
    match :get_alternate_servers, :on => :collection
    collection do
      get :currently_running
      get :server_properties
      get :properties_options
      get :runtime_phases_options
      get :environment_types_options
      get :environments_options
      get :step_component_options
      get :estimate_calculation
      get :render_output_step_view
      get :new_step_for_procedure
      delete :destroy_step_in_procedure
      post :create_procedure_step
      put :change_step_status

    end

    member do
      put :update_uploads
      get :edit_step_in_procedure
      put :update_procedure_step
      get :can_delete_step
    end
  end

  resources :application_packages do
    member do
      get :edit_property_values
      put :update_property_values
      post :update_property_values
    end
  end

  match '/requests/:request_id/properties' => 'properties#properties_for_request', :as => :properties_for_request
  match 'requests/:id/update_state/:transition' => 'requests#update_state', :as => :update_state_request, :transition => /plan|start|hold|problem|cancel|resolve|reopen/
    match 'requests/:id/add_category/:transition' => 'requests#add_category', :as => :add_category_request, :transition => /plan|start|hold|problem|cancel|resolve|reopen/, :via => :get
  match 'requests/:id/add_message/:transition' => 'requests#add_message', :as => :add_message_request, :transition => /plan|start|hold|problem|cancel|resolve|reopen/, :via => :get
  match 'requests/:id/send_message/:transition' => 'requests#send_message', :as => :send_message_request, :transition => /plan|start|hold|problem|cancel|resolve|reopen/, :via => :put
  scope 'dashboard' do
    match '/steps/currently_running' => 'steps#currently_running', :as => :dashboard_currently_running, :for_dashboard => true
  end

  resources :scheduled_jobs, :only => [:index, :show] # => :index

  resources :groups do

    collection do
      get :show_picker
    end

    member do
      get :show_picker
      put :set_default
      put :activate
      put :deactivate
    end

  end

  resources :resources do
    collection do
      get :group_allocations
    end
    member do
      get :allocate
      put :update_workstreams
      get :shift_workstreams
      get :allocations_by_group
    end
  end

  resources :placeholder_resources
  match '/resources/:id/remove_workstream/:workstream_id' => 'resources#remove_workstream', :as => :remove_workstream_resource, :via => :delete
  match '/my_resources' => 'resources#my_resources', :as => :my_resources, :via => :get
  resources :containers do
    member do
      put :activate
      put :deactivate
    end
  end

  # borrowing the ticket index with a plan filter to simulate a restful member route on plans
  match '/plans/:id/tickets' => 'tickets#index', :as => :tickets_plan

  ### FIXME, 2012-05-31, Manish, controllers, models etc to be re-factored
  #resources :plans, :as => :plans do
  resources :plans do
    collection do
      post :update_plan_templates_list
      post :update_plan_member_list
      get :plan_stage_options
      get :release_calendar
      get :get_deleted_plans
      get :archived
      get :environments_calendar
      get :filter
      post :filter
    end
    member do
      get :select_members
      put :enroll_members
      post :promote_members
      post :demote_members
      post :update_members_statuses
      post :create_activity
      get :applications
      get :start_request
      get :update_state
      get :version_report
      put :reorder
      get :reorder
      put :unassigned_reorder
      get :unassigned_reorder
      delete :delete_env_date
      get :constraints
    end

    resources :plan_routes, :only => [:index, :show, :new, :create, :destroy] do
      member do
        post :add_constraints
      end
    end

    match :move_requests, :on => :member
    match :ticket_summary_report, :on => :member
    match :ticket_summary_report_csv, :on => :member

    resources :plan_wikis do
      member do
        get :history
      end
    end

    #CHKME: This may need to be removed.
    resources :integration_csvs do
      collection do
        post :parse
      end
    end

    resources :runs do
      member do
        get :refresh
        get :version_conflict_report
        get :reorder_members
        put :start
      end

      match :update_member_order, :on => :member

      collection do
        post :add_requests
        post :select_run_for_ammendment
        post :drop
        post :toggle_parallel
      end
    end
  end

  match '/plans/:id/prepare_activity/:plan_stage_id' => 'plans#prepare_activity', :as => :prepare_activity_plan, :via => :get
  resources :activities do
    collection do
      get :creation_attributes
    end
    member do
      get :modify_deliverable
      put :save_deliverable
      post :save_deliverable
      delete :destroy_deliverable
      get :show_read_only
      get :load_requests
    end
    resources :requests do
      member do
        get :setup_schedule
        put :commit_schedule
      end
    end
  end

  match '/activity_categories/:activity_category_id/activities/new' => 'activities#new', :as => :new_activity, :via => :get
  match '/activities/:id/edit/:activity_tab_id' => 'activities#edit', :as => :edit_activity_tab, :via => :get
  match '/request_projects' => 'activities#request_projects', :as => :request_projects, :via => :get
  match 'activities/:id/show_read_only/:activity_tab_id' => 'activities#show_read_only', :as => :show_read_only_activity_tab, :via => :get

  resources :activity_categories do
    member do
      post :filter_index_columns
      get :edit_index_columns
      put :update_index_columns
      post :create_index_columns
      delete :destroy_index_columns
      get :list
    end
  end

  resources :requests do

    collection do
      get :previous
      get :application_environment_options
      get :application_process_options
      get :deployment_window_options
      get :deployment_window_next
      get :deployment_window_warning
      post :create_consolidated
      get :package_template_items_for_steps
      get :template_item_properties
      get :deleted_requests
      get :choose_environment_for_template
      get :all_notes_for_request
      get :import_xml
      post :import
      get :schedule_from_event
      post :create_from_event
      get :multi_environments
    end
    match :create_from_template, :on => :collection

    member do
      get :reorder_steps
      get :add_procedure
      get :add_new_procedure
      get :notes_by_user
      get :notes_by_time
      get :notes_by_step
      get :activity_by_time
      get :activity_by_user
      get :activity_by_step
      get :collapse_header
      get :expand_header
      get :modify_details
      get :notification_options
      get :server_properties_for_step
      get :env_visibility
      get :change_status
      get :apply_template
      get :get_status
      get :needs_update
      get :summary
      get :activity_summary
      get :update_request_info
      get :select_tickets_from_plan
      get :property_summary
      get :export_xml
      get :load_request_steps
      get :set_unset_auto_refresh
      get :show_steps
      post :update_notes
    end
    match :component_versions, :on => :member
    match :paste_steps, :on => :member
    match :new_clone, :on => :member
    match :create_clone, :on => :member

    resources :steps do
      collection do
        get :add
        get :update_server_selects
        get :bulk_update
        delete :bulk_update
        put :bulk_update
        get :search
        get :load_tab_data
        get :get_type_inputs
        get :get_package_instances
        get :references_for_request
      end
      match :update_script, :on => :collection
      match :add_uploads_via_ajax, :on => :collection

      member do
        put :update_position
        get :expand_procedure
        get :collapse_procedure
        put :update_procedure
        get :new_procedure_step
        put :toggle_execution
        get :edit_execution_condition
        put :update_execution_condition
        get :get_section
        get :add_uploads_form
        put :add_uploads
        put :update_should_execute
        put :run_now
        put :update_runtime_phase
        put :update_completion_state
        post :add_note

      end

      match :update_status, :on => :member
      match :update_details, :on => :member
      match :add_category, :on => :member

    end

    resources :uploads do
      member do
        delete :destroy
      end
    end

    resources :messages
    resource :request_templates
  end

  resources :promotions do
    collection do
      post :promotion_table
    end


  end

  match 'procedures/:procedure_id/steps/:id/update_position' => 'procedures#update_step_position', :as => :update_position_procedure_step
  match 'requests/:request_id/procedures/:procedure_id/steps/:step_id' => 'steps#edit', :as => :edit_request_parent_step
  resources :users do
    collection do
      get :show_picker
      get :bladelogic
      put :update_bladelogic_user
      get :rbac_import
      get :change_password
    end
    member do
      get :show_picker
      put :activate
      put :deactivate
      put :update_password
      put :update_last_response
      post :associate_app
      delete :disassociate_app
      put :update_roles
      get :applications
    end
  end
  resources :roles do
    member do
      put :activate
      put :deactivate
    end
  end

  post 'team_group_app_env_roles/set'

  match 'reports/process' => 'reports#index' , :as =>:reports
  match 'reports/generate_charts' => 'reports#generate_charts', :as => :generate_charts_reports
  match 'reports/edit_chart_details' => 'reports#edit_chart_details', :as => :edit_chart_details_reports
  match 'reports/number_of_deploys' => 'reports#number_of_deploys', :as => :number_of_deploys_reports
  match 'reports/time_to_complete' => 'reports#time_to_complete', :as => :time_to_complete_reports
  match 'reports/delayed_deploys' => 'reports#delayed_deploys', :as => :delayed_deploys_reports
  match 'reports/environment_options' => 'reports#environment_options', :as => :environment_options_reports
  match 'reports/generate_csv' => 'reports#generate_csv', :as => :generate_csv_reports
  match 'reports/problem_trend_report' => 'reports#problem_trend_report', :as => :problem_trend_reports
  match 'reports/problem_time' => 'reports#problem_time', :as => :problem_time_reports
  match 'reports/completed_report' => 'reports#completed_report', :as => :completed_report_reports
  match 'reports/volume_report' => 'reports#volume_report', :as => :volume_report_reports
  match 'reports/time_of_problem_report' => 'reports#time_of_problem', :as => :time_of_problem_reports
  match 'reports/toggle_filter' => 'reports#toggle_filter', :as => :toggle_filter_reports
  match 'reports/set_filter_session' => 'reports#set_filter_session', :as => :set_filter_session
  match 'reports/requests' => 'reports#requests', :as => :requests_of_app
  match 'reports/maps' => 'maps#index', :as => :maps
  match 'reports/maps/versions_by_app' => 'maps#versions_by_app', :as => :versions_by_app_maps
  match 'reports/maps/components_by_environment' => 'maps#components_by_environment', :as => :components_by_environment_maps
  match 'reports/maps/servers_by_app' => 'maps#servers_by_app', :as => :servers_by_app_maps
  match 'reports/maps/servers_by_environment' => 'maps#servers_by_environment', :as => :servers_by_environment_maps
  match 'reports/maps/properties' => 'maps#properties', :as => :properties_maps
  match 'reports/maps/servers' => 'maps#servers', :as => :servers_maps
  match 'reports/maps/logical_servers' => 'maps#logical_servers', :as => :logical_servers_maps
  match 'reports/maps/application_environment_and_component_options_for_app' => 'maps#application_environment_and_component_options_for_app', :as => :application_environment_and_component_options_for_app_maps
  match 'reports/maps/application_environment_options_for_app' => 'maps#application_environment_options_for_app', :as => :application_environment_options_for_app_maps
  match 'reports/maps/server_options_for_environment' => 'maps#server_options_for_environment', :as => :server_options_for_environment_maps
  match 'reports/maps/component_options_for_app' => 'maps#component_options_for_app', :as => :component_options_for_app_maps
  match 'reports/maps/properties_app_selected' => 'maps#properties_app_selected', :as => :properties_app_selected_maps
  match 'reports/maps/property_value_history' => 'maps#property_value_history', :as => :property_value_history_maps
  match 'reports/maps/application_component_summary' => 'maps#application_component_summary', :as => :application_component_summary_maps
  match 'reports/maps/component_options' => 'maps#component_options', :as => :component_options_maps
  match 'reports/maps/property_options' => 'maps#property_options', :as => :property_options_maps
  match 'reports/maps/server_aspect_group_options' => 'maps#server_aspect_group_options', :as => :server_aspect_group_options_maps
  match 'reports/maps/multiple_application_environment_options' => 'maps#multiple_application_environment_options', :as => :multiple_application_environment_options_maps
  match 'reports/maps/environments' => 'maps#environments', :as => :environments_maps
  match 'reports/generate_report_data_as_csv' => 'reports#generate_report_data_as_csv', :as => :generate_report_data_as_csv

  match 'reports/release_calendar' => 'reports#release_calendar',
    :as => :release_calendar_reports
  match 'reports/environment_calendar' => 'reports#environment_calendar',
    :as => :environment_calendar_reports
  match 'reports/deployment_windows_calendar' => 'reports#deployment_windows_calendar',
    :as => :deployment_windows_calendar_reports

  match 'reports/set_resolution_session' => 'reports#set_resolution_session', :as => :set_resolution_session
  match '/users/search/' => 'users#search'
  match '/properties/search/' => 'properties#search'
  match '/environment/servers/search/' => 'servers#search'
  match '/environment/capistrano/search' => 'account#search'
  match '/environment/bladelogic/search' => 'account#search'
  match '/environment/server_groups/search' => 'server_groups#search'
  match '/environment/server_level_groups/search' => 'server_aspect_groups#search'
  match '/environment/server_levels/search' => 'server_levels#search'
  match '/activity_categories/:id' => 'activity_categories#show'
  match '/activity_categories/:id' => 'activity_categories#show'
  match '/automation_results/*path' => 'output#render_output_file'
  namespace :reports do
    resources :calendars do
      member do
        get :report
      end
    end

    namespace :access do
      get 'index'
      get 'roles_map'
      post 'roles_map_report'
      get 'groups_options_for_teams'
      get 'users_options_for_groups'
    end
  end

  resources :teams do
    collection do
      post :get_user_list_of_groups
      get :team_groups
    end
    member do
      put :activate
      put :deactivate
      post :manage_apps_and_users
      get :app_user_list
      get :show_groups
      post :add_groups
      post :remove_groups
      post :add_apps
      post :remove_apps
    end
  end

  resources :feeds
  resources :component_templates do
    collection do
      post :sync
    end
    member do
      get :component_properties
    end
  end

  resources :security_questions
  resources :project_servers do
    member do
      put :activate
      put :deactivate
      post :build_parameters
    end
    resources :integration_projects do
      member do
        put :activate
        put :deactivate
      end
    end
  end

  #CHKME: I fixed a  type in the spelling of "releases" on the path, but I do not see references to this path in the current UI -- remove?
  match '/integration_projects/:id/get_releases' => 'integration_projects#get_releases', :as => :get_integration_releases, :method => :get

  resources :request_templates do
    collection do
      post :save_variant
      get :create_variant
      post :choose
      get :details
    end
    member do
      put :archive
      put :unarchive
      get :request_template_warning
    end
  end
  match 'request_templates/:id/:updater_method/:transition' => 'request_templates#update_object_state', :as => :update_state_request_templates, :updater_method => /update_object_state|update_object_state_list/, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get
  match 'plan_templates/:id/:updater_method/:transition' => 'plan_templates#update_object_state', :as => :update_state_plan_templates, :updater_method => /update_object_state|update_object_state_list/, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get
  match 'procedures/:id/:updater_method/:transition' => 'procedures#update_object_state', :as => :update_state_procedures, :updater_method => /update_object_state|update_object_state_list/, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get
  match 'deployment_window/series/:id/:updater_method/:transition' => 'deployment_window/series#update_object_state', :as => :update_state_deployment_window_series, :updater_method => /update_object_state|update_object_state_list/, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get
  match 'scripts/:id/:updater_method/:transition' => 'scripts#update_object_state', :as => :update_state_scripts, :updater_method => /update_object_state|update_object_state_list/, :transition => /make_private|begin_testing|release|archival|retire|reopen/, :method => :get


  resources :notification_templates

  # a new route to handle constraint deletions and creations from
  # various spots in the application, first and foremost plan stage instances
  resources :constraints, :only => [:destroy, :update, :create]

end
