require 'spec_helper'

describe ReleasesController, type: :controller do
  #### common values
  model = Release
  factory_model = :release
  can_archive = true
  #### values for index
  models_name = 'releases'
  model_index_path = 'index'
  be_sort = true
  per_page = 20
  index_flash = 'No Releases'
  #### values for edit
  model_edit_path = '/environment/metadata/releases'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for create
  model_create_path = '/environment/metadata/releases'
  create_params =  { release: { name: 'Release1' }}
  #### values for update
  update_params = { name: 'Release_changed' }
  #### values for destroy
  model_delete_path = '/environment/metadata/releases'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)
  it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  let(:release) { create(:release) }

  it '#show' do
    get :show, id: release.id
    expect(response).to redirect_to(edit_release_path(release))
  end

  it '#reorder' do
    put :reorder, { id: release.id,
                    release: { insertion_point: 2 }}
    release.reload
    expect(release.insertion_point).to eq 2
    expect(response).to render_template(partial: 'releases/_release')
  end
end