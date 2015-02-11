################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class FeedsController < ApplicationController

  skip_before_filter :authenticate_user!

  layout false

  def index
    Time.zone = params[:time_zone] unless params[:time_zone].nil_or_empty?
    @requests = Request.complete
  end


end

