################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

Brpm::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
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
