require 'spec_helper'

describe CategoriesController, type: :controller do
  #### common values
  model = Category
  factory_model = :category
  can_archive = true
  #### values for index
  models_name = 'categories'
  model_index_path = 'index'
  be_sort = true
  per_page = 20
  index_flash = 'No Category'
  #### values for edit
  model_edit_path = '/environment/metadata/categories'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for create
  model_create_path = '/environment/metadata/categories'
  create_params =  { category: { name: 'Category1',
                                 associated_events: ['problem'],
                                 categorized_type: 'request'}}
  #### values for update
  update_params = { name: 'name_ch' }
  #### values for destroy
  model_delete_path = '/environment/metadata/categories'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)
  it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  context '#associated_event_options with categorized type' do
    before(:each) { @category = create(:category) }

    specify 'step' do
      get :associated_event_options, { id: @category.id,
                                       category: {categorized_type: 'step'}}
      expect(response.body).to include('Empty list')
    end

    specify 'request' do
      get :associated_event_options, { id: @category.id,
                                       category: {categorized_type: 'request'}}
      expect(response.body).to include('Problem')
    end

    specify 'nil' do
      get :associated_event_options, { id: @category.id,
                                       category: { categorized_type: '' }}
      expect(response.body).to eq ''
    end
  end

  describe '#index' do
    it_behaves_like 'authorizable', controller_action: :index
  end

  describe '#new' do
    it_behaves_like 'authorizable', controller_action: :new
  end

  describe '#create' do
    it_behaves_like 'authorizable', controller_action: :create,
                                    http_method: :post
  end

  describe '#edit' do
    it_behaves_like 'authorizable', controller_action: :edit do
      let(:params) { { id: create(:category).id } }
    end
  end

  describe '#update' do
    it_behaves_like 'authorizable', controller_action: :update,
                                    http_method: :put do
      let(:params) { { id: create(:category).id } }
    end
  end

  describe '#destroy' do
    it_behaves_like 'authorizable', controller_action: :destroy,
                                    http_method: :delete do
      let(:params) { { id: create(:category).id } }
    end
  end

  describe '#archive' do
    it_behaves_like 'authorizable', controller_action: :archive,
                                    http_method: :put do
      let(:params) { { id: create(:category).id } }
    end
  end

  describe '#unarchive' do
    it_behaves_like 'authorizable', controller_action: :unarchive,
                                    http_method: :put do
      let(:params) { { id: create(:category).id } }
    end
  end
end
