################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

Brpm::Application.configure do
  config.cache_classes = true
  # Show full error reports are disabled and caching is turned on
  config.action_controller.consider_all_requests_local = false
  config.action_controller.perform_caching             = true
  config.action_view.cache_template_loading            = true
  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
  # make customizations to the default domain name and smtp settings in these files
  # created during the install process.
  smtp_file = File.join(Rails.root, 'config', 'smtp_settings.rb')
  if File.exist?(smtp_file)
    load smtp_file
  else
    # if there is no user defined smtp_settings.rb, then load the default 
    load File.join(Rails.root, 'config', 'smtp_settings.default.rb')
  end

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = false
  configure_mail(config)

  # since we cannot entirely control the contents of smtp_settings.rb, we should check
  # and make sure these constants have sane defaults, otherwise notification will throw errors
  unless defined?(DEFAULT_SUPPORT_EMAIL_ADDRESS) && defined?(DEFAULT_SUPPORT_EMAIL_FOOTER)
    DEFAULT_SUPPORT_EMAIL_ADDRESS = "tempstreamstep@gmail.com"
    DEFAULT_SUPPORT_EMAIL_FOOTER = "If you have any problems or questions - please email #{DEFAULT_SUPPORT_EMAIL_ADDRESS}"
  end
end

