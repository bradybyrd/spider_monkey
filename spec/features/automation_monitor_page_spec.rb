require 'spec_helper'

describe "Automation monitor page" do
  let!(:object) { create(:automation_queue_data) }
  it_behaves_like "list page", :url => '/automation_monitor' do
    let(:main_page_fields) { [:attempts] }
    let(:main_page_content) { 'Current Jobs in Queue' }
  end
end
