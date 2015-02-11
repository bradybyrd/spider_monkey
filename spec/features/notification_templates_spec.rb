require 'spec_helper'

describe "Notification Templates page" do
  let!(:object) { create(:notification_template) }
  it_behaves_like "list page", :url => '/notification_templates' do
    let(:main_page_fields) { [:description, :title, :event] }
    let(:main_page_content) { 'Notification Templates' }
  end
end
