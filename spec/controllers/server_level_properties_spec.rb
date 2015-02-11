require "spec_helper"

describe ServerLevelPropertiesController, :type => :controller do
  before (:each) do
    @server_level = create(:server_level, :name => 'SL1')
    @property = @server_level.properties.create(:name => 'prop1')
  end

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Property
        specify { get :new, server_level_id: @server_level }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Property
        specify { post :create, server_level_id: @server_level }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Property
        specify { get :edit, id: @property, server_level_id: @server_level }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Property
        specify { put :update, id: @property, server_level_id: @server_level }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete_property, ServerLevel
        specify { delete :destroy, id: @property, server_level_id: @server_level }
      end
    end
  end

  it "#new" do
    get :new, {:server_level_id => @server_level.id,
               :page => 1,
               :key => ''}
    response.should render_template(:partial => '_form')
  end

  context "#create" do
    it "success post" do
      post :create,{:server_level_id => @server_level.id,
                    :format => 'js'}
      response.should render_template('server_level_properties/save')
    end

    it "success xhr" do
      xhr :post, :create,{:server_level_id => @server_level.id,
                          :property => {:name => 'pr1'},
                          :format => 'js'}
      response.should render_template('server_level_properties/update')
    end

    it 'creates new property' do
      expect {
        xhr :post, :create, server_level_id: @server_level.id,
                            property: { name: 'new property' }
      }.to change(Property, :count).by(1)
    end

    it 'assigns new property to server level' do
      expect {
        xhr :post, :create, server_level_id: @server_level.id,
                            property: { name: 'new property' }
      }.to change(@server_level.properties, :count).by(1)
    end

    it "fails" do
      pending "No method present"
    end
  end

  it "#edit" do
    get :edit, {:id => @property.id,
                :server_level_id => @server_level.id}
    response.should render_template(:partial => '_form')
  end

  context "#update" do
    it "success" do
      put :update, {:id => @property.id,
                    :server_level_id => @server_level.id,
                    :format => 'js',
                    :property => {:default_value => 'changed_value'}}
      @property.reload
      @property.default_value.should eql('changed_value')
      response.should render_template('server_level_properties/save')
    end

    it "fails" do
      pending "No method present"
    end
  end

  context "#destroy" do
    it "success" do
      expect{delete :destroy, {:id => @property.id,
                               :server_level_id => @server_level.id,
                               :format => 'js'}
            }.to change(@server_level.properties, :count).by(-1)
    end

    it "fails" do
      pending "No method present"
    end
  end
end
