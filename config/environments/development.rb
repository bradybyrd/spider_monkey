################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

Brpm::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  
  #configure the application as threadsafe 
  config.threadsafe!

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.

  #this should stay false in the repository; if you want enhanced logging, 
  #it might be better make a temporary edit to production instead to provide full logs
  # without changing other things that will invalidate QA
  config.cache_classes = false #true # 

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching = false #should be false too for developers, unless you want to test caching  
  # config.action_controller.cache_store                 = :file_store, Rails.root +"/tmp/cache/"

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :letter_opener
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 1.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
  # disable sprockets logging
  config.assets.logger = false
  
  # set the default host name for the from address for the system
  config.action_mailer.default_url_options = { :host => 'example.dev' }

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
