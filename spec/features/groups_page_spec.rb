require 'spec_helper'

describe 'Groups page' do
  let!(:object) { create(:group) }

  context 'authorized user' do
    before { Ability.any_instance.stub(:can?).and_return(true) }

    it_behaves_like 'list page', :url => '/groups' do
      let(:main_page_fields) { [:name] }
      let(:main_page_content) { 'Groups' }
    end

    it_behaves_like 'edit page' do
      let(:url) { "/groups/#{object.id}/edit" }
      let(:edit_page_fields) {
        [
          {:name => :name, :required => true},
          {:name => :email}
        ]
      }
    end
  end

end
