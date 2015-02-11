require 'spec_helper'

describe ComponentsController, type: :controller do
  #### common values
  model = Component
  factory_model = :component
  can_archive = false
  #### values for index
  models_name = 'components'
  model_index_path = '_index'
  be_sort = true
  per_page = 30
  index_flash = I18n.t(:'activerecord.notices.not_found', model: 'Component')
  #### values for edit
  model_edit_path = '/index'
  edit_flash = I18n.t(:'activerecord.notices.not_found', model: 'Component')
  http_refer = true
  #### values for create
  model_create_path = nil
  create_params = {component: {name: 'name_changed'}}
  #### values for update
  update_params = {name: 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/components'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)
  it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  describe 'DB performance' do
    render_views

    describe '#index' do
      context 'root user' do
        it 'assigns active components' do
          sign_in create(:user, :root)
          active_components = create_list(:component, 3, :active).tap { |components_list|
            components_list.each { |component|
              component.properties << create(:property, :active) << create(:property, :inactive)
            }
          }

          get :index

          expect(assigns(:active_components)).to match_array(active_components)
        end

        it 'renders only active components' do
          active_properties_of_active_components, inactive_properties_of_active_components = [], []
          active_components = create_list(:component, 3, :active).tap do |components_list|
            components_list.each do |component|
              component.properties << active_properties_of_active_components << create(:property, :active)
              component.properties << inactive_properties_of_active_components << create(:property, :inactive)
            end
          end
          active_properties_of_active_components.map!(&:name)
          inactive_properties_of_active_components.map!(&:name)

          get :index

          expect(response.body).to include(*active_properties_of_active_components)
          expect(response.body).not_to include(*inactive_properties_of_active_components)
        end
      end
    end
  end
end
