require 'spec_helper'

describe 'Users page' do
  let!(:object) { create(:user) }
  it_behaves_like 'list page', url: '/users' do
    let(:main_page_fields) { [:name] }
    let(:main_page_content) { 'Users' }
  end
  pending "Unable to find field 'Login'" do
    it_behaves_like 'edit page' do
      let(:url) { "/users/#{object.id}/edit" }
      let(:edit_page_fields) {
        [
          {name: :first_name, required: true},
          {name: :last_name, required: true},
          {name: :email, required: true},
          {name: :login},
          {name: :contact_number},
          {name: :max_allocation},
          {name: :location},
        ]
      }
    end
  end
end
