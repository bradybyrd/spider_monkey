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


  match '/' => 'dashboard#self_services'
  match 'dashboard' => 'dashboard#index', :as => :dashboard
  match '/my-dashboard' => 'dashboard#self_services', :as => :my_dashboard

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
  match 'update_profile' => 'users#update_profile', :as => :update_profile
  match 'settings' => 'account#settings', :as => :settings
  match 'statistics' => 'account#statistics', :as => :statistics
  match 'settings_update' => 'account#update_settings', :as => :settings_update
  match 'settings/system' => 'account#system', :as => :settings_system
  match '/settings/calendar-preferences' => 'account#calendar_preferences', :as => :calendar_preferences, :via => :get


  resources :uploads
  scope 'environment' do
    match 'metadata' => 'environments#metadata', :as => :manage_metadata

    scope 'metadata' do

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

    end  # ~ scope metadata
  end # ~ scope environment

  match 'download_latest/:branch' => 'app_archive#download_latest', :as => :download_latest
  match 'search' => 'search#index', :as => :search
  resource :session

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

  resources :activities do
    collection do
      get :creation_attributes
      get :load_activities_grid
    end
    member do
      get :modify_deliverable
      put :save_deliverable
      post :save_deliverable
      delete :destroy_deliverable
      get :show_read_only
      get :load_requests
    end
  end

  match '/activity_categories/:activity_category_id/activities/new' => 'activities#new', :as => :new_activity, :via => :get
  match '/activities/:id/edit/:activity_tab_id' => 'activities#edit', :as => :edit_activity_tab, :via => :get
  match 'activities/:id/show_read_only/:activity_tab_id' => 'activities#show_read_only', :as => :show_read_only_activity_tab, :via => :get
  #match 'activities/load-data-in-activities-grid' => 'activities#load_activities', :as => :load_activity_grid, :via => :get
  
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

  resources :users do
    collection do
      get :show_picker
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

  resources :security_questions

  resources :notification_templates

end
