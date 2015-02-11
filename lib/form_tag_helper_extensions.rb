################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActionView
  module Helpers
    module FormTagHelper

      def select_tag_with_include_blank(name, option_tags = nil, options = {})
        blank_text = options.delete(:include_blank)
        include_blank = blank_text.to_bool
        blank_text = '' if blank_text == true
        option_tags = "<option value=\"\">#{blank_text}</option>#{option_tags}".html_safe if include_blank
        select_tag_without_include_blank(name, option_tags, options)
      end

      alias_method_chain :select_tag, :include_blank

    end
  end
end
