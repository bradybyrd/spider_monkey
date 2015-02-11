require "spec_helper"

describe IntegrationsHelper do
  it "#project_server_list" do
    @servers = 5.times.collect{ create(:server) }
    result = helper.project_server_list
    @servers.each { |el| result.should include(el.name) }
  end
end