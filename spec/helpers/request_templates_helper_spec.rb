require 'spec_helper'

describe RequestTemplatesHelper do
  it '#common_environments_of_apps_of_template' do
    @req = create(:request)
    @envs = 2.times.collect{ create(:environment) }
    @req.stub(:common_environments_of_apps).and_return(@envs)
    result = helper.common_environments_of_apps_of_template(@req)
    @envs.each{ |el| result.should include("<option data-deployment-policy='opened' value='#{el.id}'>#{el.name}</option>")}
  end
end