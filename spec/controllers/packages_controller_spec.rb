require 'spec_helper'

describe PackagesController do
  context '#standard_test' do
    #### common values
    model = Package
    factory_model = :package
    can_archive = false
    #### values for index
    models_name = 'packages'
    model_index_path = '_index'
    be_sort = true
    per_page = 30
    index_flash = 'No Package'
    #### values for edit
    model_edit_path = '/index'
    edit_flash = 'No Package'
    http_refer = true
    #### values for create
    model_create_path = nil
    create_params =  { package: { name: 'name_changed' }}
    #### values for update
    update_params = { name: 'name_ch' }
    #### values for destroy
    model_delete_path = '/environment/packages'

    it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
    it_should_behave_like('CRUD GET new')
    it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
    it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)
    it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
    it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)
  end

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :list, Package
        specify { get :index }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Package
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Package
        specify { post :create }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Package
        specify { get :edit, id: create(:package) }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Package
        specify { put :update, id: create(:package) }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, Package
        specify { delete :destroy, id: create(:package) }
      end

      context '#activate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, Package
        specify { put :activate, id: create(:package) }
      end

      context '#deactivate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, Package
        specify { put :deactivate, id: create(:package) }
      end
    end
  end

  context '#index' do
    it 'success' do
      get :index
      expect(response).to render_template('index')
    end
  end

  context '#create' do
    it 'success' do
      post :create, { package: {name: 'TestPackage1'}}

      expect(flash[:notice]).to include('successfully')
    end

    it 'errors_on_duplicate' do
      test_package = create(:package)
      test_package.name = 'TestPackage2'
      test_package.save

      post :create, {package: { name: test_package.name }}

      expect(flash[:notice]).to be_nil
    end

    it 'errors_on_name_too_long' do
      post :create, { package: { name: 'n' * 256 }}
      expect(flash[:notice]).to be_nil
    end

    it 'name_long_ok' do
      post :create, { package: { name: 'n' * 255}}
      expect(flash[:notice]).to include('successfully')
    end
  end

  context '#update' do
    it '#update' do
      test_package = create(:package)
      test_package.name = "TestPackage2"
      test_package.next_instance_number = 200
      test_package.instance_name_format = 'updated format'
      test_package.save

      put :update, { id: test_package.id, package: {name: 'newName'} }

      test_package.reload
      expect(test_package.name).to eq 'newName'
      expect(test_package.next_instance_number).to eq 200
      expect(test_package.instance_name_format).to eq 'updated format'
      expect(response).to redirect_to(packages_path)
      expect(flash[:notice]).to include('successfully')
    end
  end
end
