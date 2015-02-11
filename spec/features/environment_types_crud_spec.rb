require 'spec_helper'

describe "Environment Types CRUD" do
  let!(:object) { create(:environment_type) }
  it_behaves_like "list page", :url => '/environment/metadata/environment_types' do
    let(:main_page_fields) { [:name] }
    let(:main_page_content) { 'Archive' }
  end
pending "Capybara::ElementNotFound: Unable to find field \"Login\"" do
  it_behaves_like "edit page" do
    let(:url) { "/environment/metadata/environment_types/#{object.id}/edit" }
    let(:edit_page_fields) {
      [
        {:name => :name, :required => true },
        {:name => :description, :required => false}
      ]
    }
  end
  it_behaves_like "new page" do
    let(:url) { "/environment/metadata/environment_types/new" }
    let(:new_page_fields) {
      [
          {:name => :name, :required => true},
          {:name => :description, :required => false}
      ]
    }
  end
end
end
