################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

Brpm::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local        = false
  config.action_controller.perform_caching  = true
  # config.action_controller.cache_store     = :file_store, Rails.root + "/tmp/cache/"
  config.action_view.cache_template_loading = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true
  config.assets.prefix = '/portfolio/assets'
  config.action_controller.relative_url_root = "/portfolio"

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( activities.js activity_index_columns.js ajaxfileupload.js
                                  amcharts/swfobject.js apps.js automation.js bulk_delete_requests.js
                                  calendar.js chart.js dashboard.js drag_and_drop/component_drop_zone.js
                                  drag_and_drop/draggable_object.js drag_and_drop/expandable_procedures.js
                                  drag_and_drop/helpers.js drag_and_drop/jquery.ui.core.js
                                  drag_and_drop/jquery.ui.draggable.js drag_and_drop/jquery.ui.mouse.js
                                  drag_and_drop/jquery.ui.widget.js
                                  drag_and_drop/object_group_drop_zone.js drag_and_drop/table_drop_zone.js
                                  external.js filters.js groups.js ie/ie7_misc_fixes.js
                                  ie/jquery.bgiframe.min.js ie/misc_fixes.js ie/resolution_fixes.js
                                  jquery-1.3.2.min.js jquery.dimensions.js plans.js server_messages.js
                                  list_items.js maps.js multi_select.js parameter_mappings.js phases.js plan_dashboard.js project.js
                                  project_server.js promotions.js raphael.js shared_resource_automation.js server_side_sorting.js
                                  reports.js requests.js request_form.js request_templates.js resources.js runs.js
                                  search.js self_services.js server_level_instances.js server_levels.js service_now.js stdlib.js steps.js
                                  swfobject.js system_settings.js table_sorters/request_tablesorters.js
                                  teams.js tickets.js unsaved_changes_warning.js uploads.js users.js
                                  validate.js version_tags.js print.css calendar.css chat.css dashboard.css
                                  ie6.css ie7.css ie8.css ie9.css plans.css pagination.css properties.css
                                  request.css runs.css scaffold.css self_services.css table_sorting.css
                                  extra.css screen.css external.css jquery.tooltip.css multiple_picker.css multiple_picker.js
                                  select2.js select2/select2.css schedule_request_from_event.js package_edit.js package_instance_edit.js
                                  access.js app_test_env_component_selection.js)

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  config.threadsafe!

  config.dependency_loading = true if $rails_rake_task

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 1.5

  # set the default host name for the from address for the system
  config.action_mailer.default_url_options = { :host => 'example.com' }

  # make customizations to the default domain name and smtp settings in these files
  # created during the install process.
  smtp_file = File.join(Rails.root, 'config', 'smtp_settings.rb')
  if File.exist?(smtp_file)
    load smtp_file
  else
    # if there is no user defined smtp_settings.rb, then load the default
    load File.join(Rails.root, 'config', 'smtp_settings.default.rb')
  end

  # run the configuration routine from the settings file which can override for all
  # environments the settings for action mailer. Since code updates may overwrite the
  # environment specific files, put all user customizations in this external settings file.
  configure_mail(config)

 # since we cannot entirely control the contents of smtp_settings.rb, we should check
 # and make sure these constants have sane defaults, otherwise notification will throw errors
 # these should be set individually in case the user has 1 or 2, but not all three
 DEFAULT_SUPPORT_EMAIL_ADDRESS = "tempstreamstep@gmail.com" unless defined?(DEFAULT_SUPPORT_EMAIL_ADDRESS)
 DEFAULT_SUPPORT_EMAIL_FOOTER = "If you have any problems or questions - please email #{DEFAULT_SUPPORT_EMAIL_ADDRESS}" unless defined?(DEFAULT_SUPPORT_EMAIL_FOOTER)
 # this is set to the notifier default in case clients had that address working and want to keep it without setting a new one
 #DEFAULT_SUPPORT_EMAIL_FROM_ADDRESS = "no-reply@#{Notifier.default_url_options[:host]}" unless defined?(DEFAULT_SUPPORT_EMAIL_FROM_ADDRESS)
end

