require 'spec_helper'

describe EnvironmentTypesController, :type => :controller do
  #### common values
  model = EnvironmentType
  factory_model = :environment_type
  can_archive = true
  #### values for index
  models_name = 'environment_types'
  model_index_path = 'index'
  be_sort = false
  per_page = 20
  index_flash = "No Environment Type"
  #### values for edit
  model_edit_path = '/index'
  edit_flash = 'not found'
  http_refer = true
  #### values for create
  model_create_path = nil
  create_params = {:environment_type => {:name => 'EnvType1',
                                         :label_color => '#00008B'}}
  #### values for update
  update_params = {:name => 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/metadata/environment_types'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD POST create", model, factory_model, model_create_path, create_params)
  it_should_behave_like("CRUD PUT update", model, factory_model, update_params)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  describe '#reorder' do
    context 'with permissions' do
      include_context 'mocked abilities', :can, :edit, EnvironmentType

      it 'reorders environment types' do
        env_type = create(:environment_type, position: 1)

        put :reorder, {id: env_type.id,
                       environment_type: {position: '2'}}

        expect(env_type.reload.position).to eq(2)
        expect(response).to render_template(partial: 'environment_types/_environment_type')
      end
    end

    context 'without permissions' do
      include_context 'mocked abilities', :cannot, :edit, EnvironmentType

      it 'cannot reorder environment types' do
        env_type = create(:environment_type, position: 1)

        put :reorder, {id: env_type.id,
                       environment_type: {position: '2'}}

        expect(env_type.reload.position).to eq(1)
        expect(response).to redirect_to(root_path)
      end
    end

  end
end

