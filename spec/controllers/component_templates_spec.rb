require 'spec_helper'

describe ComponentTemplatesController, type: :controller do
  render_views

  before(:each) do
    @app = create(:app)
    @component = create(:component, active: true)
    @app_component = create(:application_component, app: @app,
                                                    component: @component)
    @component_temp = ComponentTemplate.create( name: 'Component_template',
                                                application_component_id: @app_component.id,
                                                app_id: @app.id)
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#new' do
        include_context 'mocked abilities', :cannot, :add, ComponentTemplate
        specify { get :new }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :add, ComponentTemplate
        specify { post :create }
      end

      context '#sync' do
        include_context 'mocked abilities', :cannot, :sync, ComponentTemplate
        specify { post :sync }
      end
    end
  end

  it '#new' do
    get :new, app_id: @app.id
    expect(response).to render_template('new')
  end

  context '#create' do
    it 'success' do
      post :create, { format: 'js',
                      component_template: { name: 'Component_temp1',
                                            application_component_id: @app_component.id,
                                            app_id: @app.id}}
      expect(response).to render_template('component_templates/_update_component_templates_list')
    end

    it 'fails' do
      ComponentTemplate.stub(:new).and_return(@component_temp)
      @component_temp.stub(:save).and_return(false)
      post :create, { format: 'js',
                      component_template: { name: 'Component_temp1',
                                            app_id: @app.id}}
      expect(response.body).to include('component_template_error_messages')
    end
  end

  it '#edit' do
    get :edit, id: @component_temp.id

    expect(assigns(:app)).to eq @app
    expect(response).to render_template('edit')
  end

  context '#update' do
    it 'success' do
      put :update, { id: @component_temp.id,
                     format: 'js',
                     component_template: { name: 'Component_temp_changed',
                                           application_component_id: @app_component.id,
                                           app_id: @app.id}}
      @component_temp.reload
      expect(@component_temp.name).to eq('Component_temp_changed')
      expect(response).to render_template('component_templates/_update_component_templates_list')
    end

    it 'fails' do
      ComponentTemplate.stub(:find).and_return(@component_temp)
      @component_temp.stub(:update_attributes).and_return(false)

      put :update, { id: @component_temp.id,
                     format: 'js',
                     component_template: { name: 'Component_temp1',
                                           application_component_id: @app_component.id,
                                           app_id: @app.id }}
      expect(response.body).to include('component_template_error_messages')
    end
  end

  it '#sync' do
    #TODO remove stub run_sync_command and test automation script running
    script_params = {'SS_script_type' => 'component_sync',
                      'SS_script_target' => 'bladelogic',
                      'result' => "STDOUT: \nscript_result\n"}
    GlobalSettings.stub(:bladelogic_ready?).and_return(true)
    ComponentTemplate.stub(:run_sync_command).and_return(script_params)
    create(:bladelogic_script)

    post :sync, { id: @component_temp.id, app_id: @app.id, format: 'js' }

    expect(assigns(:errors)).to be_nil
  end

  it '#component properties' do
    pack_temp = create(:package_template, app: @app, name: 'package_template1', version: '1.0')
    package_template_item = pack_temp.package_template_items.create

    get :component_properties, { id: @component_temp.id,
                                 package_template_item: package_template_item,
                                 template_item_count: 1,
                                 identifier: '',
                                 format: 'js' }
    expect(response).to render_template(partial: 'package_templates/template_items/forms/_component_instance_properties')
  end
end

