require 'spec_helper'

describe ListItemsController, :type => :controller do
  before (:each) do
    @list = create(:list)
  end

  context "#create" do
    it "text item whithout value" do
      put :create, {:list_id => @list.id,
                    :value => "  "}
      response.body.should include('name not allowed to be empty')
    end

    it "number item whithout value" do
      @list2 = create(:list, :is_text => false)
      put :create, {:list_id => @list2.id,
                    :value => "  "}
      response.body.should include('name not allowed to be empty')
    end
  end
end
