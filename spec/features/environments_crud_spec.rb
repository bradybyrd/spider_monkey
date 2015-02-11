require 'spec_helper'

describe "Environment CRUD" do
  let!(:object) { create(:environment) }
  pending "Unable to find field 'Login'" do
    it_behaves_like "list page", :url => '/environment/environments' do
      let(:main_page_fields) { [:name] }
      let(:main_page_content) { 'Active' }
    end
  end
  it_behaves_like "edit page" do
    let(:url) { "/environment/environments/#{object.id}/edit" }
    let(:edit_page_fields) {
      [
        {:name => :name, :required => true },
        {:name => :environment_type_id, :required => false}
      ]
    }
  end
  pending "Unable to find field 'Login'" do
    it_behaves_like "new page" do
      let(:url) { "/environment/environments/new" }
      let(:new_page_fields) {
        [
            {:name => :name, :required => true},
            {:name => :environment_type_id  , :required => false}
        ]
      }
    end
  end
end
