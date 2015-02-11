################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# Be sure to restart your server when you modify this file.

if defined?($servlet_context)

  Rails.logger.info "Using tomcat servlet store..."

  require 'action_controller/session/java_servlet_store'
  # tell rails to use the java container's session store
  Brpm::Application.config.session_store = :java_servlet_store

else

  require 'digest/md5'

  cur_host = `hostname`.chomp
  new_key = "_brpm_session_#{Rails.env}_#{cur_host + Digest::MD5.hexdigest(Rails.root.to_s)}"

  if GlobalSettings.connection.table_exists?(GlobalSettings.table_name) # Wrapper for rake tasks
    session_key = GlobalSettings[:session_key]
    if session_key.nil?
      session_key = new_key
      GlobalSettings[:session_key] = session_key
    end
  else
    session_key = new_key
  end

  if defined? Torquebox
    Brpm::Application.config.session_store :torquebox_store, {
        :key => session_key,
        #:domain => 'foobar.com',
        #:path => '/baz',
        :httponly => false,
        :secure => false
        #:max_age => 600, # seconds
        #:timeout => 180 # seconds
    }

  else
    Brpm::Application.config.session_store :cookie_store, key: session_key
  end  
end


# ActionController::Base.session = {
#  :session_key => session_key,
#  :secret      => "96684b50119871470b03785218d1fe08201d9c2a3e7cb3be7ba26b864a3292da0f22d573949c2cd66442c580d3296d536fbe94c26a69e0a871d13e8b3275bec6"
#}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Brpm::Application.config.session_store :active_record_store
