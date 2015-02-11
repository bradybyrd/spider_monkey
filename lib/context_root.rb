################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ContextRoot

  def ContextRoot.context_root
    ctx_root = ENV['RAILS_RELATIVE_URL_ROOT']
    if ctx_root.nil?
      ""
    else
      ctx_root
    end
  end

end
