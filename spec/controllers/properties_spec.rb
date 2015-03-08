require 'spec_helper'

describe PropertiesController, type: :controller do
  before(:each) do
    @property = create(:property)
    @component = create(:component)
  end

  #### common values
  model = Property
  factory_model = :property
  can_archive = false
  #### values for index
  models_name = 'properties'
  model_index_path = '_index'
  be_sort = true
  per_page = 30
  index_flash = 'no properties'
  #### values for edit
  model_edit_path = '/environment/apps'
  edit_flash = nil
  http_refer = nil
  #### values for destroy
  model_delete_path = '/environment/properties'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  it '#show' do
    pending 'missing template'
    get :show, id: @property.id

    expect(response).to render_template('show')
  end

  it '#new' do
    app = create(:app)

    get :new, { object: 'app', object_id: app.id }

    expect(assigns(:property).app_ids).to include(app.id)
  end

  it '#edit_values' do
    pending 'No route'
    get :edit_values, id: @property.id

    expect(response).to render_template('edit')
  end

  context '#create' do
    context 'success' do
      it 'creates new element and redirect' do
        post :create, { property: { name: 'Property1',
                                    component_ids: [@component.id] }}

        expect(response.code).to eq '302'
      end

      it 'returns flash notice' do
        post :create, { property: { name: 'Property1',
                                    component_ids: [@component.id] },
                        format: 'js'}

        expect(flash[:notice]).to include('successfully')
        expect(response).to render_template('misc/redirect')
      end
    end

    context 'fails' do
      before(:each) do
        Property.stub(:new).and_return(@property)
        @property.stub(:save).and_return(false)
      end

      it 'renders template new' do
        post :create, { property: { name: 'Property1',
                                    component_ids: [@component.id] }}
        expect(response).to render_template('new')
      end

      it 'returns validation errors' do
        post :create, { property: { name: 'Property1',
                                    component_ids: [@component.id]},
                        format: 'js'}
        expect(response).to render_template('misc/error_messages_for')
      end
    end
  end

  context '#update' do
    context 'success' do
      it 'changes attributes' do
        put :update, { id: @property.id,
                       property: { name: 'Property_changed',
                                   component_ids: [@component.id] }}

        @property.reload
        expect(@property.name).to eq 'Property_changed'
        expect(flash[:notice]).to include('successfully')
        expect(response).to redirect_to properties_path
      end

      it 'returns flash notice' do
        put :update, { id: @property.id,
                       format: 'js',
                       property: { name: 'Property_changed',
                                   component_ids: [@component.id] }}
        @property.reload
        expect(@property.name).to eql('Property_changed')
        expect(flash[:notice]).to include('successfully')
        expect(response).to render_template('misc/redirect')
      end
    end

    context 'fails' do
      before(:each) do
        Property.stub(:find).and_return(@property)
        @property.stub(:update_attributes).and_return(false)
      end

      it 'changing attributes' do
        put :update, { id: @property.id,
                       property: { name: 'Property_changed',
                                   component_ids: [@component.id]}}
        expect(response).to render_template('edit')
      end

      it 'returns validation errors' do
        put :update, { id: @property.id,
                       format: 'js',
                       property: { name: 'Property_changed',
                                   component_ids: [@component.id] }}
        expect(response).to render_template('misc/error_messages_for')
      end
    end
  end

  context '#properties_for_request' do
    before(:each) do
      pending "Missing template properties/properties_for_request, application/properties_for_request\nrank 2"
      @my_request = create(:request)
      @installed_component = create(:installed_component)
      @version_tag = create(:version_tag)
      @work_task = create(:work_task)
      @params = { id: @installed_component.id,
                  request_id: @my_request.number,
                  component_id: @component.id,
                  version_tag_id: @version_tag.id,
                  component_version: '2.0',
                  work_task_id: @work_task.id,
                  load_component_version: '1' }
    end

    it 'render property_installed_components' do
      get :properties_for_request, @params

      expect(response).to render_template(partial: 'steps/_property_installed_components')
    end

    it 'render property_values' do
      @params[:load_component_version] = '0'

      get :properties_for_request, @params

      expect(response).to render_template(partial: 'steps/_property_values')
    end
  end

  it '#reorder' do
    comp_property = ComponentProperty.create(component_id: @component.id, property_id: @property.id)

    get :reorder, { id: @property.id,
                    component_id: @component.id,
                    property: { insertion_point: 3 }}

    comp_property.reload
    expect(comp_property.insertion_point).to eq 3
    expect(response).to render_template(partial: 'properties/_property_list')
  end
end
