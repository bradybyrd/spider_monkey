################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# CAS Authentication Configuration
# rake app:cas_auth:on # Enable CAS Authentication
# rake app:cas_auth:off # Disable CAS Authentication

require 'casclient'
require 'casclient/frameworks/rails/filter'

if GlobalSettings.connection.table_exists?(GlobalSettings.table_name) && GlobalSettings.cas_enabled?
  #### Security Note - Never embed an external link in the application ####
  cas_url = GlobalSettings[:cas_server].nil? ? "127.0.0.1" : GlobalSettings[:cas_server]
  cas_logger = CASClient::Logger.new(Rails.root.to_s+'/log/cas.log')
  cas_logger.level = Logger::DEBUG
  puts "SS__ Setting CAS Authentication - Server: #{cas_url}" if GlobalSettings.cas_enabled?
  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url => cas_url,
    :username_session_key => :cas_user,
    :logger => cas_logger
  )
end