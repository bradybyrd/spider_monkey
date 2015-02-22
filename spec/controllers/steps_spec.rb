require 'spec_helper'

describe StepsController, type: :controller do
  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @app_env = create(:application_environment, app: @app, environment: @env)
    AssignedEnvironment.create!(environment_id: @env.id, assigned_app_id: @app.assigned_apps.first.id, role: @user.roles.first)
    @request1 = create(:request, apps: [@app], environment_id: @env.id)
    @step1 = create(:step, request: @request1)
  end

  context '#index' do
    specify 'completed request' do
      Request.any_instance.stub(:complete?).and_return(true)

      get :index, request_id: @request1.number

      expect(response).to render_template('steps/request_complete')
    end

    context 'not completed request' do
      it 'renders nothing' do
        @request1.steps.delete_all

        get :index, request_id: @request1.number

        expect(response).to_not render_template('index')
      end

      it "renders template 'steps/index'" do
        step2 = create(:step, request: @request1)
        @request1.plan_it!
        @request1.start!
        @request1.aasm_state.should eql('started')
        @step1.reload
        @step1.lets_start!
        @step1.reload
        @step1.all_done!
        @step1.reload
        expect(@step1.aasm_state).to eq 'complete'

        get :index, { request_id: @request1.number,
                      unfolded_steps: step2.id.to_s,
                      format: 'js' }

        expect(response).to render_template('steps/index')
      end

      specify 'procedure and child steps' do
        @step1.procedure = true
        @step1.save
        step2 = create(:step, request: @request1)
        @procedure = create(:procedure)
        step2.parent_id = @step1
        @step1.steps << step2

        get :index, {:request_id => @request1.number,
                     :unfolded_steps => step2.id.to_s,
                     :format => 'js'}
      end
    end
  end

  it '#add' do
    get :add, { request_id: @request1.number,
                id: @step1.id,
                format: 'js' }
    expect(response).to render_template('add')
  end

  it '#get_section' do
    get :get_section, { request_id: @request1.number,
                        id: @step1.id }
    expect(response).to render_template(partial: 'steps/step_rows/_step_show_form')
  end

  context '#currently_running' do
    it_behaves_like 'authorizable', controller_action: :currently_running,
                                    ability_action: :view_currently_running_steps,
                                    subject: Request

    it 'returns records with pagination and renders partial' do
      per_page = 2
      create_list(:step, per_page + 1)
      Step.stub(:all_currently_running).and_return(Step.scoped)

      xhr :get, :currently_running, {page: 1, per_page: per_page}

      expect(assigns(:steps).size).to eq(per_page)
      expect(response).to render_template(partial: 'dashboard/self_services/_currently_running_steps.html')
    end

    it 'returns records of current user' do
      @request1.plan_it!
      @request1.start!
      @step1.reload
      @step1.lets_start!

      get :currently_running, {:for_dashboard => true}

      expect(response).to render_template('dashboard/self_services')
    end

    it 'returns page path should_user_include_groups=true' do
      get :currently_running, should_user_include_groups: true

      expect(assigns(:page_path)).to include('should_user_include_groups=true')
    end

    it 'returns page path dashboard_currently_running_url' do
      get :currently_running
      expect(response).to render_template('steps/currently_running')
    end
  end

  context '#update_components' do
    before(:each) do
      @component = create(:component)
    end

    it 'deletes steps' do
      Step.any_instance.stub(:request).and_return( double('request').as_null_object )

      expect{
        get :update_components, {steps: [@step1.id],
                                 components: { @step1.id.to_s => '' },
                                 redirect_path: 'requests_path' }
      }.to change(@request1.steps, :count).by(-1)
      expect(response).to redirect_to('requests_path')
    end

    it 'deletes components' do
      pending '#update_components action should be rewritten. Request has no association app(should be apps)'
      session[:components_to_be_destroyed] = [@component.id]
      create(:application_component,
              app: @app,
              component: @component)
      get :update_components, {steps: [@step1.id],
                               components: {"#{@step1.id}" => ''},
                               redirect_path: 'requests_path'}
      session[:components_to_be_destroyed].should be_nil
    end

    it 'updates components' do
      pending '#update_components action should be rewritten. Request has no association app(should be apps)'
      get :update_components, {steps: [@step1.id],
                               components: {"#{@step1.id}" => @component.id},
                               redirect_path: 'requests_path'}
      @step1.reload
      @step1.component_id.should eql(@component.id)
    end
  end

  describe '#new' do
    before do
      Request.stub(:find_by_number).and_return(@request1)
    end

    it_behaves_like 'authorizable', controller_action: :new,
                                    ability_action: :add_step,
                                    subject: Request,
                                    params: {request_id: 1, token: '123z'}
    it '#new' do
      get :new, { request_id: @request1.number,
                  parallel: true }
      expect(response).to render_template(partial: 'steps/step_rows/_step_form')
    end
  end

  describe '#load_tab_data' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :step_tab_permission, Request
      it 'redirects to root path' do
        get :load_tab_data, request_id: @request1.number, li_id: 'st_documents'
        expect(response).to redirect_to root_path
      end
    end

    it 'renders template' do
      get :load_tab_data, { id: @step1.id,
                            request_id: @request1.number,
                            li_id: 'st_documents',
                            format: 'js' }
      expect(response).to render_template('load_tab_data')
    end
  end

  describe '#references_for_request' do
    render_views
    context 'step creation' do
      it 'should return empty content tab' do
        get :references_for_request, {
          step: { package_id: ''},
          id: '',
          package_or_instance: :package,
          request_id: @request1.number
        }

        expect(response).to render_step_references
        expect(response.body).to eq ''
      end

      it 'should return content tab html li element hidden' do
        get :new, {
            request_id: @request1.number,
            parallel: true
        }

        expect(response).to render_step_form
        expect(response.body).to include "<li class='' id='st_content' style='visibility:hidden'>"
      end

      it 'should return package references in content tab' do
        package = create(:package)
        package.references.create({server_id: 1, uri: 'abcd', name: 'test'})

        get :references_for_request, {
            step: { package_id: package.id},
            id: '',
            package_or_instance: :package,
            request_id: @request1.number
        }

        expect(response).to render_step_references
        expect(response.body).to include 'test'
        expect(response.body).to include 'abcd'
      end

      it 'should return package references in content tab checked' do
        package = create(:package)
        package.references.create({server_id: 1, uri: 'abcd', name: 'test'})

        get :references_for_request, {
          step: { package_id: package.id},
          id: '',
          package_or_instance: :package,
          request_id: @request1.number
        }

        expect(response).to render_step_references
        expect(response.body).to include 'test'
        expect(response.body).to include 'abcd'
        expect(response.body).to include '<td><input checked="checked" id="step_references_'
      end
    end


  context 'existing step' do
    it 'should return content tab with unchecked references' do
      package = create(:package)
      package.references.create({server_id: 1, uri: 'abcd', name: 'test'})

        get :references_for_request, {
            step: { package_id: package.id},
            id: @step1.id,
            package_or_instance: :package,
            request_id: @request1.number
        }

        expect(response).to render_step_references
        expect(response.body).to include 'type="checkbox" value="true" />'
      end

      it 'should return content tab with checked reference' do
        package = create(:package)
        reference = create(:reference, {name: 'test', package: package})
        @step1.step_references.destroy_all
        @step1.step_references << create(:step_reference, step_id: @step1.id, reference_id: reference.id,
                                         owner_object_id: reference.id,
                                         owner_object_type: Reference.to_s)
        get :references_for_request, {
            step: { package_id: package.id},
            id: @step1.id,
            package_or_instance: :package,
            request_id: @request1.number
        }

        expect(response).to render_step_references
        expect(response.body).to include '<td><input checked="checked" id="step_references_'
      end

      it 'should return content tab html li element visible' do
        temp = @step1.related_object_type
        @step1.related_object_type = 'package'
        @step1.save

        get :edit, {
            request_id: @request1.number,
            id: @step1.id,
        }

        expect(response).to render_step_form
        expect(response.body).to include "<li class='' id='st_content'>"
        @step1.related_object_type = temp
        @step1.save
      end
    end
  end

  def render_step_references
    render_template(partial: 'steps/step_rows/_step_references')
  end

  def render_step_form
    render_template(partial: 'steps/step_rows/_step_form')
  end

  describe '#new_step_for_procedure' do
    let(:procedure) { create :procedure }

    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :add_step, Request
      it 'redirects to root path' do
        get :new_step_for_procedure, request_id: @request1.number
        expect(response).to redirect_to root_path
      end
    end

    context 'authorized' do
      include_context 'mocked abilities', :can, :add_step, Request
      it 'succeeds' do
        get :new_step_for_procedure, request_id: @request1.number, procedure_id: procedure.id
        expect(response.status).to eq 200
      end
    end

    context 'authorization' do
      context 'on /metadata/procedures' do
        let(:user) { create :old_user, :not_admin_with_role_and_group }
        let(:permissions) { user.groups.first.roles.first.permissions }
        let(:add_step_permission) { create :permission, name: 'Add New Step', action: :add_step, subject: 'Request' }

        it 'opens popup' do
          sign_in user
          permissions << add_step_permission

          get :new_step_for_procedure, procedure_id: procedure.id

          expect(response).to render_template('steps/step_rows/_new_step_for_procedure_form')
        end
      end
    end

    it 'renders template' do
      procedure = create(:procedure)
      procedure.apps << @app
      get :new_step_for_procedure, { procedure_id: procedure.id,
                                     parallel: true}
      expect(response).to render_template(partial: 'steps/step_rows/_new_step_for_procedure_form')
    end
  end

  context '#create' do
    before(:each) do
      @component = create(:component)
      GlobalSettings.stub(:limit_versions?).and_return(false)
    end

    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :add_step, Request
      it 'redirects to root path' do
        post :create
        expect(response).to redirect_to root_path
      end
    end

    context 'limit versions true' do
      before(:each) do
        GlobalSettings.stub(:limit_versions?).and_return(true)
        @version_tag = create(:version_tag)
      end

      it 'fails and redirects to edit request path' do
        Request.stub(:find_by_number).and_return(@request1)
        @request1.steps.stub(:build).and_return(@step1)
        @step1.stub(:save).and_return(false)

        post :create, { request_id: @request1.number,
                        step: { component_id: @component.id }}

        expect(assigns(:validation_errors)).to be_truthy
        expect(response).to redirect_to(edit_request_path(@request1) + "#step_#{@step1.id}_#{@step1.position}_heading")
      end

      it 'success' do
        @request1.environment_id = @env.id
        @request1.save
        @app_component = create(:application_component, app: @app, component: @component)
        @installed_component = create(:installed_component,
                                      application_component: @app_component,
                                      application_environment: @app_env)
        expect{
          post :create, { request_id: @request1.number,
                          step: { component_id: @component.id,
                                  version: @version_tag.id,
                                  name: 'Step name1',
                                  manual: true,
                                  description: 'A sample step description.',
                                  procedure: false,
                                  should_execute: true }}
        }.to change(Step, :count).by(1)
      end
    end

    context 'with params arguments' do
      before(:each) do
        @script = create(:general_script)
        @pr_server = create(:project_server)
        @version_tag = create(:version_tag)
        @request1.environment_id = @env.id
        @request1.save
        create_installed_component
      end

      it 'success with argument params' do
        @arguments = ScriptArgument.all
        ScriptArgument.stub(:find).and_return(@arguments[0])
        @arguments[0].stub(:is_required?).and_return(true)
        expect{
          post :create, { request_id: @request1.number,
                          step: { component_id: @component.id,
                                  version: @version_tag.id,
                                  name: 'Step name1',
                                  manual: true,
                                  description: 'A sample step description.',
                                  procedure: false,
                                  should_execute: true },
                          argument: { @arguments[0].id => 'val1' }}
        }.to change(Step, :count).by(1)
      end

      it 'success with tree_renderer params' do
        arguments = ScriptArgument.all
        expect{
          post :create, { request_id: @request1.number,
                          step: { component_id: @component.id,
                                  version: '2' },
                          "tree_renderer_#{arguments[0].id}" => 'val01,val02,val03' }
        }.to change(Step, :count).by(1)
      end
    end

    it 'renders template errors' do
      Request.stub(:find_by_number).and_return(@request1)
      @request1.steps.stub(:build).and_return(@step1)
      @step1.stub(:save).and_return(false)

      post :create, {request_id: @request1.number,
                     step: {component_id: @component.id,
                            version: '2'},
                     ajax_request: true,
                     unfolded_steps: "#{@step1.id}"}

      expect(assigns(:validation_errors)).to be_truthy
      expect(response).to render_template('misc/error_messages_for')
    end

    it 'renders partial ajax file submit' do
      @request1.environment_id = @env.id
      @request1.save
      app_component = create(:application_component, :app => @app, :component => @component)
      create(:installed_component, application_component: app_component,
                                   application_environment: @app_env)

      post :create, { request_id: @request1.number,
                      step: { component_id: @component.id,
                              version: '2',
                              name: 'Step name1',
                              manual: true,
                              description: 'A sample step description.',
                              procedure: false,
                              should_execute: true },
                      ajax_request: true }
      expect(response).to render_template(partial: 'steps/step_rows/_ajax_file_submit')
    end
  end

  it '#create_procedure_step' do
    component = create(:component)
    procedure = create(:procedure)
    expect{
      post :create_procedure_step, {request_id: @request1.number,
                                    step: {component_id: component.id,
                                           version: '2',
                                           name: 'Step name1',
                                           manual: true,
                                           description: 'A sample step description.',
                                           procedure: false,
                                           should_execute: true,
                                           procedure_id: procedure.id},
                                    ajax_request: true}
    }.to change(Step, :count).by(1)
    expect(response).to render_template(partial: 'steps/step_rows/_ajax_file_submit')
  end

  it '#show' do
    get :show, {:request_id => @request1.number, :id => @step1.id}
    expect(response).to render_template(partial: 'steps/step_rows/_step_header')
  end

  it "#edit" do
    get :edit, {:request_id => @request1.number, :id => @step1.id}
    expect(response).to render_template(:partial => 'steps/step_rows/_step_form')
  end

  describe '#edit_step_in_procedure' do
    it 'renders procedure step template' do
      procedure = create(:procedure)
      procedure.apps << @app

      get :edit_step_in_procedure, {request_id: @request1.number,
                                    id: @step1.id,
                                    procedure_id: procedure.id}

      expect(response).to render_template(partial: 'steps/step_rows/_procedure_step_form')
      expect(assigns(:users)).to include(@user)
    end

    context 'archived procedure' do
      it 'redirects' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        get :edit_step_in_procedure, id: step.id,
                                     procedure_id: procedure.id

        expect(response).to redirect_to(root_path)
      end
    end
  end

  context '#update_position' do
    before(:each) do
      @request1.plan_it!
      @request1.start!
      @request1.put_on_hold!
      @step1.procedure = true
      @step1.save
    end

    it 'renders partial procedure for reorder' do
      put :update_position, { request_id: @request1.number,
                              id: @step1.id,
                              procedure_step: { insertion_point: 2 }}
      @step1.reload
      expect(@step1.insertion_point).to eq 2
      expect(response).to render_template(partial: 'steps/_procedure_for_reorder')
    end

    it 'renders partial step for reorder' do
      step2 = create(:step, :request => @request1)
      @step1.steps << step2
      put :update_position, { request_id: @request1.number,
                              id: @step1.id,
                              step_id: step2.id,
                              step: { insertion_point: 1 }}
      step2.reload
      expect(step2.insertion_point).to eq 1
      expect(response).to render_template(partial: 'steps/_step_for_reorder')
    end
  end

  context '#update' do
    before(:each) do
      @component = create(:component)
      GlobalSettings.stub(:limit_versions?).and_return(false)
    end

    context 'mutually exclusive package and component' do
      before (:each) do
        @property1 = create(:property, name: 'prop 1', active: true)
        @package = create(:package, properties: [@property1])
        @app.packages = [@package]
        @application_package = @app.application_packages[0]
        @mutual_step = create(:step, request: @request1)
      end

      it 'removes component if package is selected' do
        @mutual_step.installed_component_id = @component.id
        @mutual_step.save
        request_hash = {request_id: @request1.number,
                        id: @mutual_step.id,
                        step: { installed_component_id: '',
                                package_id: @package.id },
                        property_values: { application_package: { @application_package.id => { @property1.id => 'new value'} } } }
        put :update, request_hash
        @mutual_step.reload
        expect(@mutual_step.installed_component_id).to be_nil
        expect(@mutual_step.package_id).to eq @package.id
      end

      it 'removes package if component is selected' do
        @mutual_step.package = @package
        @mutual_step.save
        request_hash = { request_id: @request1.number,
                         id: @mutual_step.id,
                         step: { component_id: @component.id,
                                package_id: ''}
                        }
        put :update, request_hash
        @mutual_step.reload
        expect(@mutual_step.component_id).to eq @component.id
        expect(@mutual_step.package_id).to be_nil
      end
    end

    context 'property value' do
      before(:each) do
        @property1 = create(:property, name: 'prop 1', active: true)
        @package = create :package, properties: [@property1]
        @app.packages = [@package]
        @application_package = @app.application_packages[0]
        @step1.package = @package
      end

      it 'should have saved propery value for step' do
        request_hash = {request_id: @request1.number,
                        id: @step1.id,
                        step: { component_id: @component.id,
                                package_id: @package.id },
                        property_values: { application_package: { @application_package.id => { @property1.id => "new value" } } } }
        put :update, request_hash
        @step1.reload

        result_map = {}
        @step1.collect_package_properties( result_map, false )
        expect( result_map ).to have_key('prop 1')
        expect( result_map['prop 1'] ).to eq 'new value'
      end
    end

    context 'limit versions true' do
      before(:each) do
        GlobalSettings.stub(:limit_versions?).and_return(true)
      end

      it 'fails and redirects to edit request path' do
        Request.stub(:find_by_number).and_return(@request1)
        @request1.steps.stub(:find_by_id).and_return(@step1)
        @step1.stub(:update_attributes).and_return(false)
        version_tag = create(:version_tag)

        put :update, { request_id: @request1.number,
                       id: @step1.id,
                       step: { component_id: @component.id,
                               version: version_tag.id }}
        expect(response).to render_template('misc/error_messages_for')
      end

      it 'success' do
        script = create(:general_script)
        server = create(:server)
        server_level = create(:server_level)
        server_aspect = create(:server_aspect,
                                server_level_id: server_level.id,
                                parent: create(:server_aspect))
        put :update, { request_id: @request1.number,
                       id: @step1.id,
                       step: { component_id: @component.id,
                              :version => '-1',
                              :name => 'Step name1',
                              :manual => true,
                              :description => 'A sample step description.',
                              :procedure => true,
                              :should_execute => true,
                              :script_id => script.id,
                              :server_ids => ["sa_#{server_aspect.id}"]
                      },
                      automation_type: 'automation'}
        @step1.reload
        #@step1.script_id.should eql(@script.id)
        expect(response).to redirect_to(edit_request_path(@request1) + "#step_#{@step1.id}_#{@step1.position}_heading")
      end
    end

    context 'with params arguments' do
      before(:each) do
        @script = create(:general_script)
        @pr_server = create(:project_server)
        @version_tag = create(:version_tag)
        @request1.environment_id = @env.id
        @request1.save
        create_installed_component
      end

      it 'success with argument params' do
        arguments = ScriptArgument.all
        ScriptArgument.stub(:find).and_return(arguments[0])
        arguments[0].stub(:is_required?).and_return(true)

        put :update, { request_id: @request1.number,
                       id: @step1.id,
                       step: { component_id: @component.id,
                               version: '-1',
                               name: 'Step name1',
                               manual: true,
                               description: 'A sample step description.',
                               procedure: true,
                               should_execute: true,
                               script_id: @script.id},
                      automation_type: 'automation',
                      argument: { arguments[0].id => 'val1' }}
        @step1.reload

        expect(@step1.script_id).to eq @script.id
      end

      it 'success with tree_renderer params' do
        arguments = ScriptArgument.all
        put :update, { request_id: @request1.number,
                       id: @step1.id,
                       step: { component_id: @component.id,
                               version: '2',
                               script_id: @script.id},
                       automation_type: 'automation',
                       "tree_renderer_#{arguments[0].id}" => 'val01,val02,val03' }
        @step1.reload
        expect(@step1.script_id).to eq @script.id
      end
    end

    context 'package with params arguments' do
      before(:each) do
        @script = create(:general_script)
        @pr_server = create(:project_server)
        @version_tag = create(:version_tag)
        @request1.environment_id = @env.id
        @request1.save
        create_app_package
      end

      it 'success with argument params' do
        arguments = ScriptArgument.all
        ScriptArgument.stub(:find).and_return(arguments[0])
        arguments[0].stub(:is_required?).and_return(true)

        put :update, {request_id: @request1.number,
                      id: @step1.id,
                      step: {package_id: @package.id,
                             related_object_type: 'package',
                             latest_package_instance: false,
                             create_new_package_instance: false,
                             version: '-1',
                             name: @step1.name,
                             manual: false,
                             description: 'A sample step description.',
                             procedure: true,
                             should_execute: true,
                             script_id: @script.id},
                      automation_type: 'General',
                      argument: {arguments[0].id => 'val1package'}}
        @step1.reload
        expect(@step1.script_id).to eq @script.id
      end
    end

    it 'deletes server associations and renders partial steps' do
      create(:server)
      create(:server_aspect, server_level: create(:server_level))

      put :update, {request_id: @request1.number,
                    id: @step1.id,
                    step: {component_id: @component.id,
                           version: '-1',
                           name: 'Step name1',
                           manual: true,
                           description: 'A sample step description.',
                           procedure: true,
                           should_execute: true},
                    change_server_ids_flag: true,
                    internet_explorer_fix: true}
      expect(response).to render_template(partial: 'requests/_steps')
      @step1.reload
      expect(@step1.server_ids).to eq []
      expect(@step1.server_aspect_ids).to eq []
    end
  end

  describe '#update_procedure_step' do
    it 'updates name' do
      script = create(:general_script)
      @step1.procedure = true
      @step1.script_id = script.id
      @step1.save
      put :update_procedure_step, {id: @step1.id,
                                   step: {version: '-1',
                                             name: 'name_changed',
                                             manual: true,
                                             description: 'A sample step description.',
                                             procedure: true,
                                             should_execute: true,
                                             script_id: script.id},
                                   internet_explorer_fix: true,
                                   automation_type: 'manual'}
      @step1.reload
      expect(@step1.name).to eq 'name_changed'
    end

    context 'archived procedure' do
      it 'redirects' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        put :update_procedure_step, { id: step.id,
                                      step: { procedure_id: procedure.id,
                                              name: 'The brand new name'} }
        expect(response).to redirect_to(root_path)
      end

      it 'does not change step' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        expect {
          put :update_procedure_step, { id: step.id,
                                        step: { procedure_id: procedure.id,
                                                name: 'The brand new name'} }
        }.not_to change { step.reload.attributes }
      end
    end
  end

  context '#update_uploads' do
    it 'renders partial' do
      put :update_uploads, { id: @step1.id,
                             step: { name: 'name_changed' },
                             ajax_upload: true }
      @step1.reload
      expect(@step1.name).to eq 'name_changed'
      expect(response).to render_template(partial: '_ajax_documents_upload_form')
    end

    it 'redirects back' do
      @request.env["HTTP_REFERER"] = '/index'

      put :update_uploads, id: @step1.id

      expect(response).to redirect_to('/index')
    end
  end

  context '#update_script' do
    before(:each) do
      @component = create(:component)
    end

    xit 'BladelogicScript' do
      script = create(:bladelogic_script)
      put :update_script, {request_id: @request1.number,
                           id: @step1.id,
                           component_id: @component_id,
                           step_owner_type: 'User',
                           step_owner_id: @user.id,
                           script_type: 'BladelogicScript',
                           'script_id' => script.id}
      expect(response).to render_template(partial: 'steps/bladelogic/_step_script')
    end

    it 'Automation' do
      script = create(:general_script)
      put :update_script, {:request_id => @request1.number,
                           :component_id => @component_id,
                           :step_owner_type => 'User',
                           :step_owner_id => @user.id,
                           :script_type => 'AutomationScript',
                           'script_id' => script.id}
      expect(response).to render_template(partial: 'steps/_step_script')
    end
  end

  describe '#get_package_instances' do
    render_views
    before(:each) do
      @package = create(:package)
      @app.packages = [@package]
      @application_package = @app.application_packages[0]
      @step1.package = @package
      @step1.request = @request1
    end

    it 'has create_new selected' do
      @step1.create_new_package_instance = true
      @step1.save
      get :get_package_instances, {request_id: @request1.number,
                                   step_id: @step1.id,
                                   package: @package.id}
      expect(response.body).to include "<option value=\"create_new\" selected=\"selected\">"
    end

    it 'has latest selected' do
      @step1.latest_package_instance = true
      @step1.save
      get :get_package_instances, {request_id: @request1.number,
                                   step_id: @step1.id,
                                   package: @package.id}
      expect(response.body).to include "<option value=\"latest\" selected=\"selected\">"
    end

  end

  describe '#update_procedure' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :edit_procedure, Request
      it 'redirects to root path' do
        put :update_procedure, { request_id: @request1.number,
                                 id: @step1.id,
                                 step: {name: 'Procedure_name_changed'},
                                 format: 'js' }

        expect(response).to redirect_to root_path
      end
    end

    it 'renders template' do
      put :update_procedure, { request_id: @request1.number,
                               id: @step1.id,
                               step: {name: 'Procedure_name_changed'},
                               format: 'js'}
      @step1.reload
      expect(@step1.name).to eq 'Procedure_name_changed'
      expect(response).to render_template('update_procedure')
    end
  end


  it '#update_should_execute' do
    put :update_should_execute, { request_id: @request1.number,
                                  id: @step1.id,
                                  step: { should_execute: true },
                                  format: 'js' }
    @step1.reload
    expect(@step1.should_execute).to be_truthy
  end

  describe '#change_step_status' do
    it 'changes should_execute field value' do
      put :change_step_status, { request_id: @request1.number,
                                 id: @step1.id,
                                 step: {should_execute: true},
                                 format: 'js'}
      @step1.reload
      expect(@step1.should_execute).to be_truthy
    end

    context 'archived procedure' do
      it 'redirects' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        put :change_step_status, step: { should_execute: true }, id: step.id

        expect(response).to redirect_to(root_path)
      end

      it 'does not change step' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        expect { put :change_step_status, step: { should_execute: true }, id: step.id }
        .not_to change { step.reload.should_execute }
      end
    end
  end

  it '#update_runtime_phase' do
    runtime_phase = create(:runtime_phase, :phase => create(:phase))
    put :update_runtime_phase, { request_id: @request1.number,
                                 id: @step1.id,
                                 step: {runtime_phase_id: runtime_phase.id},
                                 format: 'js' }
    @step1.reload
    expect(@step1.should_execute).to be_truthy
  end

  it '#update_completion_state' do
    put :update_completion_state, { request_id: @request1.number,
                                    id: @step1.id,
                                    step: {completion_state: 'changed'},
                                    format: 'js' }
    @step1.reload
    expect(@step1.completion_state).to eq 'changed'
  end

  describe '#new_procedure_step' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :add_serial_procedure_step, Request
      it 'redirects' do
        xhr :get, :new_procedure_step, { request_id: @request1.number,
                                         id: @step1.id,
                                         procedure_add_new: true }
        expect(response).to render_template 'misc/redirect'
      end
    end

    it '#renders template' do
      xhr :get, :new_procedure_step, { request_id: @request1.number,
                                       id: @step1.id,
                                       procedure_add_new: true }
      expect(response).to render_template(partial: 'steps/step_rows/_step_form')
    end
  end

  context '#update_status' do
    before(:each) do
      @request1.plan_it!
      @request1.reload
      @request1.start!
    end

    it 'creates note with xhr' do
      expect {
        xhr :put, :update_status, { request_id: @request1.number,
                                    property_values: '',
                                    id: @step1.id,
                                    step: {},
                                    note: 'note',
                                    'start.x' => true}
      }.to change(@step1.notes, :count).by(1)
    end

    it 'redirects to ' do
      put :update_status, { request_id: @request1.number,
                            property_values: '',
                            id: @step1.id,
                            step: {},
                            'start.x' => true }
      expect(response).to redirect_to(edit_request_path(@request1, unfolded_steps: nil))
    end

    it 'starts' do
      put :update_status, { request_id: @request1.number,
                            id: @step1.id,
                            'start.x' => true }
      @step1.reload
      expect(@step1.aasm_state).to eq 'in_process'
    end

    it 'resolve' do
      @step1.reload
      @step1.lets_start!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'resolve.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'in_process'
    end

    it 'problem' do
      @step1.reload
      @step1.lets_start!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'problem.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'problem'
    end

    it 'block' do
      @step1.reload
      @step1.lets_start!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'block.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'blocked'
    end

    it 'unblock' do
      @step1.reload
      @step1.lets_start!
      @step1.block!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'unblock.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'in_process'
    end

    it 'completes' do
      pending "TypeError: incompatible marshal file format (can't be read)"
      @step1.reload
      @step1.lets_start!
      @step1.all_done!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'complete.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'complete'
    end

    it 'resets' do
      @step1.reload
      @step1.lets_start!
      @step1.all_done!
      put :update_status, {request_id: @request1.number,
                           id: @step1.id,
                           'reset.x' => true}
      @step1.reload
      expect(@step1.aasm_state).to eq 'in_process'
    end
  end

  context '#add_note' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :view_step_notes_tab, Request
      it 'redirects to root path' do
        post :add_note, {id: @step1.id, request_id: @request1.number, note: 'note'}

        expect(response).to redirect_to root_path
      end
    end

    it 'success' do
      expect{
        post :add_note, { id: @step1.id,
                          request_id: @request1.number,
                          note: 'note' }
      }.to change(@step1.notes, :count).by(1)
      expect(response).to render_template(partial: 'steps/_step_notes_values')
    end

    it 'fails' do
      post :add_note, { id: @step1.id,
                        request_id: @request1.number,
                        note: '' }
    end
  end

  describe '#destroy' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :remove_procedure, Request
      it 'redirects to root path' do
        delete :destroy, {id: @step1.id, request_id: @request1.number}

        expect(response).to redirect_to root_path
      end
    end

    it 'redirects back' do
      @request.env['HTTP_REFERER'] = '/reorder_steps/'
      expect{xhr :delete, :destroy, {:id => @step1.id,
                                     :request_id => @request1.number}
      }.to change(Step, :count).by(-1)
      expect(response).to redirect_to('/reorder_steps/')
    end

    it 'redirects to edit request path' do
      delete :destroy, { id: @step1.id,
                         request_id: @request1.number }
      expect(response).to redirect_to(edit_request_path(@request1))
    end
  end

  describe '#destroy_step_in_procedure' do
    it 'changes steps count and redirects to edit' do
      procedure = create(:procedure)
      Step.stub(:find).and_return(@step1)
      @step1.stub(:floating_procedure).and_return(procedure)
      expect{
        delete :destroy_step_in_procedure, { id: @step1.id,
                                             request_id: @request1.number }
      }.to change(Step, :count).by(-1)
      expect(response).to redirect_to(edit_procedure_path(procedure))
    end

    context 'archived procedure' do
      it 'redirects' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        delete :destroy_step_in_procedure, id: step.id

        expect(response).to redirect_to(root_path)
      end

      it 'does not destroy step' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        expect { delete :destroy_step_in_procedure, id: step.id }
        .not_to change { Step.count }
      end
    end
  end

  it '#add_category' do
    get :add_category, {id: @step1.id,
                        request_id: @request1.number,
                        associated_event: 'problem'}
    expect(response).to render_template(partial: 'steps/_add_category')
  end

  it '#expand_procedure' do
    get :expand_procedure, {id: @step1.id,
                            request_id: @request1.number}
    expect(response).to render_template(partial: 'steps/_expanded_procedure_for_reorder')
  end

  it '#collapse_procedure' do
    get :collapse_procedure, {id: @step1.id,
                              request_id: @request1.number}
    expect(response).to render_template(partial: 'steps/_procedure_for_reorder')
  end

  it '#update_server_selects' do
    server = create(:server)
    server_group = create(:server_group)
    get :update_server_selects, { id: @step1.id,
                                  request_id: @request1.number,
                                  step: { server_group_ids: [server_group.id],
                                         server_ids: [server.id] },
                                  format: 'js' }
    expect(assigns(:selected_server_groups)).to include(server_group)
    expect(assigns(:selected_servers)).to include(server)
  end

  it '#toggle_execution' do
    put :toggle_execution, {id: @step1.id,
                            request_id: @request1.number,
                            step: {name: 'toggle_changed_name'}}
    @step1.reload
    expect(@step1.name).to eq 'toggle_changed_name'
  end

  it '#server_properties' do
    server_level = create(:server_level)
    server_aspect = create(:server_aspect, server_level: server_level)
    get :server_properties, { id: @step1.id,
                              server_level_id: server_level.id,
                              step: { server_aspect_ids: [server_aspect.id] }
                              }
    expect(assigns(:server_aspects)).to include(server_aspect)
    expect(assigns(:properties)).to match_array(server_level.properties)
  end

  context '#edit_execution_condition' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :edit_procedure_execute_conditions, Request
      it 'redirects to root path' do
        get :edit_execution_condition, {id: @step1.id, request_id: @request1.number}

        expect(response).to redirect_to root_path
      end
    end

    it "returns condition_type 'property'" do
      get :edit_execution_condition, { id: @step1.id,
                                       request_id: @request1.number }
      expect(assigns(:condition_type)).to eq 'property'
      expect(response).to render_template('edit_execution_condition')
    end

    it 'returns step execution condition' do
      create_installed_component
      @env.requests << @request1
      step2 = create(:step, :request => @request1)
      step2.create_execution_condition(condition_type: 'environments',
                                       referenced_step_id: @step1.id,
                                       environment_ids: [@env.id])

      get :edit_execution_condition, { id: step2.id,
                                       request_id: @request1.number }
      expect(assigns(:condition_type)).to eq 'environments'
    end
  end

  describe '#update_execution_condition' do
    context 'not authorized' do
      include_context 'mocked abilities', :cannot, :edit_procedure_execute_conditions, Request
      it 'redirects to root path' do
        put :update_execution_condition, { id: @step1.id,
                                           request_id: @request1.number,
                                           clear: true }

        expect(response).to redirect_to root_path
      end
    end

    it '#update_execution_condition' do
      put :update_execution_condition, {id: @step1.id,
                                        request_id: @request1.number,
                                        clear: true}
      expect(response).to redirect_to(@request1)
    end
  end

  context '#run_now' do
    it "returns flash notice 'undefined method'" do
      put :run_now, { id: '-1',
                      request_id: @request1.number }
      expect(flash[:notice]).to include('undefined method')
    end

    it 'success' do
      Step.stub(:find_by_id).and_return(@step1)
      script = create(:general_script)
      @step1.stub(:script).and_return(script)
      put :run_now, { id: @step1.id,
                      request_id: @request1.number}
    end
  end

  it '#properties_options' do
    step2 = create(:step, :request => @request1)
    get :properties_options, {id: @step1.id,
                              execution_condition: {referenced_step_id: step2.id}}
    expect(response.body).to include('')
  end

  context '#runtime_phases_options' do
    before(:each) do
      @phase = create(:phase)
      @runtime_phase = create(:runtime_phase, phase: @phase)
    end

    specify 'with execution_condition' do
      @step1.phase = @phase
      @step1.save
      get :runtime_phases_options, {id: @step1.id,
                                    execution_condition: {referenced_step_id: @step1.id}}
      expect(response.body).to include(@runtime_phase.name)
    end

    specify 'without execution_condition' do
      get :runtime_phases_options, { id: @step1.id,
                                     step: { phase_id: @phase.id }}
      expect(response.body).to include(@runtime_phase.name)
    end
  end

  it '#environment_types_options' do
    env_type = create(:environment_type)
    get :environment_types_options, { id: @step1.id,
                                      request_id: @request1.number }
    expect(response.body).to include(env_type.name)
  end

  it '#environments_options' do
    get :environments_options, {id: @step1.id,
                                request_id: @request1.number,
                                execution_condition: {referenced_step_id: @step1.id}}
    expect(response.body).to include(@env.name)
  end

  context '#get_alternate_servers' do
    before(:each) do
      create_installed_component
      @server = create(:server)
    end

    it 'returns step servers associations' do
      get :get_alternate_servers, {id: @step1.id,
                                   step_id: @step1.id,
                                   app_id: @app.id,
                                   component_id: @component.id,
                                   environment_id: @env.id}
      expect(response).to render_template(partial: 'steps/_alternate_server_property_values')
    end

    it 'returns only installed component servers associations' do
      get :get_alternate_servers, {id: @step1.id,
                                   app_id: @app.id,
                                   component_id: @component.id,
                                   environment_id: @env.id,
                                   installed_component_id: @installed_component.id}
      expect(response).to render_template(partial: 'steps/_alternate_server_property_values')
    end
  end

  describe '#bulk_update' do
    context 'not authorized' do
      context 'when can not delete steps' do
        include_context 'mocked abilities', :cannot, :delete_steps, @request1
        it 'redirects to root path' do
          get :bulk_update, {request_id: @request1.number,
                             step_ids: [@step1.id],
                             apply_action: 'delete',
                             operation: 'modify_assignment'}

          expect(response).to redirect_to root_path
        end
      end

      context 'when can not turn_on_off_steps' do
        include_context 'mocked abilities', :cannot, :turn_on_off_steps, @request1
        it 'redirects to root path' do
          get :bulk_update, {request_id: @request1.number,
                             step_ids: [@step1.id],
                             apply_action: 'modify_should_execute',
                             operation: 'modify_assignment'}

          expect(response).to redirect_to root_path
        end
      end
    end

    context 'request steps' do
      it 'renders template bulk update' do
        get :bulk_update, {request_id: @request1.number,
                           step_ids: [@step1.id],
                           operation: 'modify_assignment'}
        expect(response).to render_template('steps/bulk_update', layout: false)
      end

      it "delete step execution condition" do
        pending 'step has_one :execution_condition association does not specify dependent: destroy option, that is why StepExecutionCondition.count will not be changed!'
        step2 = create(:step, request: @request1)
        property = create(:property)
        component = create(:component)
        property_value = create(:property_value, property: property, value_holder_id: component.id)
        phase = create(:phase)
        runtime_phase = create(:runtime_phase, phase: phase)
        step2.create_execution_condition( condition_type: 'property',
                                          referenced_step_id: @step1.id,
                                          value: property_value.value,
                                          property_id: property.id)
        expect{
          delete :bulk_update, { request_id: @request1.number,
                                 step_ids: [@step1.id],
                                 apply_action: 'delete' }
        }.to change(StepExecutionCondition, :count).by(-1)
      end

      it 'modify should execute' do
        get :bulk_update, {request_id: @request1.number,
                           step_ids: [@step1.id],
                           apply_action: 'modify_should_execute',
                           step: {should_execute: 'true'}}
        @step1.reload
        expect(@step1.should_execute).to be_truthy
      end

      it 'update installed component' do
        create_installed_component
        server = create(:server)
        @installed_component.servers << server
        @env.requests << @request1
        @request1.save

        get :bulk_update, {request_id: @request1.number,
                           step_ids: [@step1.id],
                           apply_action: 'modify_assignment',
                           step: {should_execute: true,
                                  component_id: @component.id}}
        @step1.reload
        expect(@step1.server_ids).to include(server.id)
      end

      it 'modifies app component and renders index' do
        get :bulk_update, {request_id: @request1.number,
                           step_ids: [@step1.id],
                           apply_action: 'modify_app_component',
                           format: 'js',
                           step: {should_execute: true,
                                  component_id: ''}}
        @step1.reload
        expect(@step1.script).to be_nil
        expect(response).to render_template('steps/index')
      end
    end

    context 'bulk_update_procedure_steps' do
      before(:each) do
        @step1.procedure = true
        @procedure = create(:procedure)
        @procedure.apps = [@app]
        @step2 = @procedure.steps.new(owner: @user,
                                      name: 'Step_name',
                                      different_level_from_previous: true,
                                      manual: true,
                                      description: 'A sample step description.',
                                      procedure: false,
                                      should_execute: true,
                                      parent_id: @step1.id)
        @step2.save
        @procedure.save
      end

      it 'renders template bulk update' do
        get :bulk_update, {request_id: '-1',
                           step_ids: [@step2.id],
                           operation: 'modify_assignment'}
        expect(response).to render_template('steps/bulk_update', layout: false)
      end

      it 'deletes steps' do
        expect{
          delete :bulk_update, { request_id: '-1',
                                 step_ids: [@step2.id],
                                 apply_action: 'delete',
                                 format: 'js' }
        }.to change(Step, :count).by(-1)
        expect(response).to render_template('misc/redirect')
      end

      it 'modify should execute' do
        @procedure.steps.new(owner: @user,
                             name: 'Step_name',
                             different_level_from_previous: true,
                             manual: true,
                             description: 'A sample step description.',
                             procedure: false,
                             should_execute: true)
        @procedure.save
        get :bulk_update, {request_id: '-1',
                           step_ids: [@step2.id],
                           apply_action: 'modify_should_execute',
                           step: {should_execute: true},
                           format: 'js'}
        @step2.reload
        expect(@step2.should_execute).to be_truthy
        expect(response).to render_template('steps/render_steps')
      end

      it 'updates server ids' do
        create_installed_component
        server = create(:server)
        @installed_component.servers << server
        @step2.stub(:installed_component).and_return(double('installed_component', present: true, server_association_ids: [server.id]))
        Step.stub(:where).and_return([@step2])
        @env.requests << @request1

        get :bulk_update, { request_id: '-1',
                            step_ids: [@step2.id],
                            apply_action: 'modify_assignment',
                            step: { should_execute: 'true',
                                    component_id: @component.id }}
        expect(@step2.server_ids).to include(server.id)
      end

      it 'modify app component and renders index' do
        get :bulk_update, {request_id: '-1',
                           step_ids: [@step2.id],
                           apply_action: 'modify_app_component',
                           step: {should_execute: true,
                                  component_id: ''}}
        @step2.reload
        expect(@step2.script).to be_nil
      end
    end

    context 'archived procedure' do
      it 'redirects to root path' do
        procedure = create :procedure, :archived, :with_steps
        step = procedure.steps.first

        get :bulk_update, { request_id: '-1', step_ids: [step.id], format: :js }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  context '#step_component_options' do
    it 'returns installed components' do
      create_installed_component
      @request1.environment_id = @env.id
      @request1.save

      get :step_component_options, { id: @step1.id,
                                     request_id: @request1.id,
                                     step: { app_id: @app.id }}

      expect(response.body).to include(@component.name)
    end

    it 'returns blank options' do
      get :step_component_options, id: @step1.id
      expect(response.body).to eq "<option value=''>Select</option>"
    end
  end

  context '#can_delete_step' do
    before(:each) do
      @step2 = create(:step, request: @request1)
    end

    it "renders text 'step is used in procedure'" do
      property = create(:property)
      component = create(:component)
      property_value = create(:property_value, property: property, value_holder_id: component.id)
      phase = create(:phase)
      runtime_phase = create(:runtime_phase, phase: phase)
      @step2.create_execution_condition(condition_type: 'property',
                                        referenced_step_id: @step1.id,
                                        value: property_value.value,
                                        property_id: property.id)

      get :can_delete_step, {request_id: @request1.number, id: @step1.id}

      expect(response.body).to include('Step is used in procedure')
    end

    it "renders test 'Are you sure'" do
      get :can_delete_step, {request_id: @request1.number, id: @step2.id}

      expect(response.body).to include('you want to delete')
    end
  end

  it '#estimate_calculation' do
    get :estimate_calculation, { request_id: @request1.number,
                                 c_d: '02/03/2013 05:06 AM',
                                 s_d: '02/04/2013 05:06 AM' }
    expect(response.body).to include('24,0')
  end

  context '#render_output_step_view' do
    before(:each) do
      create_installed_component
      @script = create(:general_script)
    end

    specify 'Input' do
      get :render_output_step_view, {step_id: @step1.id,
                                     installed_component_id: @installed_component.id,
                                     script_id: @script.id,
                                     parameter_type: 'Input'}
      expect(response).to render_template(partial: 'steps/_step_script')
    end

    specify 'Output' do
      get :render_output_step_view, {step_id: @step1.id,
                                     installed_component_id: @installed_component.id,
                                     script_id: @script.id,
                                     parameter_type: 'Output'}
      expect(response).to render_template(partial: 'steps/_step_script')
    end
  end

  context '#render_output_step_view no component' do
    before(:each) do
      @script = create(:general_script)
    end

    specify 'Input' do
      get :render_output_step_view, {step_id: @step1.id,
                                     script_id: @script.id,
                                     parameter_type: 'Input'}
      expect(response).to render_template(partial: 'steps/_step_script')
    end

    specify 'Output' do
      get :render_output_step_view, {step_id: @step1.id,
                                     script_id: @script.id,
                                     parameter_type: 'Output'}
      expect(response).to render_template(partial: 'steps/_step_script')
    end
  end

  def create_installed_component
    @request1.environment_id = @env.id
    @component = create(:component)
    @app_component = create(:application_component, app: @app, component: @component)
    @installed_component = create(:installed_component,
                                  application_environment: @app_env,
                                  application_component: @app_component)
  end

  def create_app_package
    @request1.environment_id = @env.id
    @package = create(:package)
    @app_package = create(:application_package, app: @app, package: @package)
  end

  describe '#references step selections' do
    context 'step references empty if non selected and didnt open content tab' do
      it 'no references changed' do
        controller.params = { test: 'Y' }
        params2 = controller.update_step_references( {} )

        expect(params2).to_not include(:reference_ids)
      end
    end

    context 'step references empty if non selected and did open content tab' do
      it 'references cleared to empty array' do
        controller.params = { test: 'Y', content_tab_viewed: 'Y' }
        params2 = controller.update_step_references( {} )

        expect(params2).to include(:reference_ids)
        expect(params2[:reference_ids]).to eq []
      end
    end

    context 'step references selected' do
      it 'references as input' do
        controller.params = { test: 'Y', content_tab_viewed: 'Y', step_references:{'1' => 'true', '2' => 'true'} }
        params2 = controller.update_step_references ( {} )

        expect(params2).to include(:reference_ids)
        expect(params2[:reference_ids]).to eq %w(1 2)
      end
    end
  end
end