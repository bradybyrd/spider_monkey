################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

Brpm::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Enable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = false

  # set the default host name for the from address for the system
  config.action_mailer.default_url_options = { :host => 'example.com' }

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

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
  unless defined?(DEFAULT_SUPPORT_EMAIL_ADDRESS) && defined?(DEFAULT_SUPPORT_EMAIL_FOOTER)
    DEFAULT_SUPPORT_EMAIL_ADDRESS = "tempstreamstep@gmail.com"
    DEFAULT_SUPPORT_EMAIL_FOOTER = "If you have any problems or questions - please email #{DEFAULT_SUPPORT_EMAIL_ADDRESS}"
  end
end

