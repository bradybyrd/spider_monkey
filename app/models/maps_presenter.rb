################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class MapsPresenter

  def raw_map
    @build ||= []
  end

  def reset_map!
    @build = []
  end

  def to_html build = self.raw_map
    total = '<ul>'
    build.each do |val|
      if String === val
        total << "<li>#{val}</li>"
      else
        total << to_html(val)
      end
    end
    total << '</ul>'
  end


end

