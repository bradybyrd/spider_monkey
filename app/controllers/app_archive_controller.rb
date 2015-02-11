################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AppArchiveController < ApplicationController
  skip_before_filter :authenticate_user!

  def download_latest
    archive = File.join(Rails.root, 'app', "latest_#{params[:branch]}.tgz")
    if File.exists? archive
      send_file archive
    else
      render :text => "application archive not found"
    end
  end

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      user && user.admin?
    end
  end
end

