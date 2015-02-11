require 'spec_helper'

describe "dashboard/self_services/tables/my_servers" do

  before(:each) do
    view.stub(:current_user) { User.current_user }
    Ability.any_instance.stub(:can?).and_return(true)
    @controller.stub(:current_ability).and_return(Ability.new(User.current_user))
  end

  it "renders form with server information" do
    server = create(:server)
    @my_servers = create_paginated(Server.all)

    render partial: "dashboard/self_services/tables/my_servers", formats: "html"
    expect(rendered).to include(server.name)
  end

  def create_paginated(records)
    WillPaginate::Collection.create(1 , 10) do |pager|
      pager.replace records[pager.offset, pager.per_page]
      unless pager.total_entries
        pager.total_entries = records.size
      end
    end
  end

end
