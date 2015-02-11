################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module PlanTemplatesHelper
  def request_template_links(request_templates = [])
    unless request_templates.empty?
      my_output = []
      request_templates.each do |request_template|
        #FIXME: facebox is not showing content under rails 3 (2012-06-15) - redirecting instead
        #my_output << link_to(request_template.name, request_request_templates_path(request_template.request.id, :preview => "yes"), :rel => 'facebox[.plan_template_request_template_preview]') if request_template
        my_output << link_to(request_template.name, request_request_templates_path(request_template.request.id, :preview => "yes")) if request_template.request
      end
    end
    return my_output.join(" | ")
  end
end
