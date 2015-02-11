require "spec_helper"

describe PlanTemplatesHelper do
  it "#request_template_links" do
    @request_templates = 2.times.collect{ create(:request_template) }
    result = helper.request_template_links(@request_templates)
    @request_templates.each { |el| result.should include("<a href=\"/requests/#{el.request.id}/request_templates?preview=yes\">#{el.name}</a>") }
  end
end