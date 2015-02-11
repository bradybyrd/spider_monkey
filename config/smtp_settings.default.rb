################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

DEFAULT_SUPPORT_EMAIL_ADDRESS = "tempstreamstep@gmail.com"
DEFAULT_SUPPORT_EMAIL_FOOTER = "If you have any problems or questions - please email #{DEFAULT_SUPPORT_EMAIL_ADDRESS}"
DEFAULT_SUPPORT_EMAIL_FROM_ADDRESS = "no-reply@example.com"
def configure_mail(config)
  # Set the :host value to a domain that your smtp or sendmail will allow for outgoing mail   
  # config.action_mailer.default_url_options = { :host => 'example.com' }
  
  # Override the mail method for all environments. Possible values are :smtp (default), :sendmail, :file and :test.
  # config.action_mailer.delivery_method = :test
  
  # Override perform deliveries for all environments. Determines whether deliver_* methods are actually carried out. By default they are,
  # but this can be turned off to help functional testing.  Change this to true to enable email.
  # config.action_mailer.perform_deliveries = false

  # To set up SMTP, uncomment the appropriate method call below, set options in the method as necessary,
  # and save the file as smtp_settings.rb
  # configure_mail_with_gmail(config)
  # configure_mail_without_gmail(config)
end

def configure_mail_with_gmail(config)
  require 'smtp_tls'

  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => "587",
    :authentication => :plain,
    :domain => "localhost.localdomain",
    :user_name => "someusername",
    :password => "somepassword"
  }
end

def configure_mail_without_gmail(config)
  config.action_mailer.smtp_settings = { 
    :address => "0.0.0.0", 
    :port => "25", 
    :domain => "localhost.localdomain"
  } 
end
