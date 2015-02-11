require 'spec_helper'

describe "Plan Routes CRUD" do

  before(:each) do
    # create an extra app because new plan_route needs
    # at least one extra, non-assigned visible route to show new form
    route = create(:route)
  end

  let!(:object) { create(:plan_route) }

  pending 'Unable to find field "Login"' do
    it_behaves_like "list page" do
      let(:url) { "/plans/#{object.plan.id}/plan_routes" }
      let(:main_page_fields) { [:route_app_name, :route_name, :route_environments_list] }
      let(:main_page_content) { 'Routes' }
    end
    it_behaves_like "show page" do
      let(:url) { "/plans/#{object.plan.id}/plan_routes/#{object.id}" }
      let(:main_page_fields) { [:route_app_name, :route_name] }
      let(:main_page_content) { 'Routes' }
    end
  end
  it_behaves_like "new page" do

    let(:url) { "/plans/#{object.plan.id}/plan_routes/new" }
    let(:new_page_fields) {
      [
          {:name => :route_app_id, :required => true},
          {:name => :route_id, :required => true}
      ]
    }
  end
end
