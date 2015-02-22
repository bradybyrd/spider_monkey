require 'spec_helper'

describe ProceduresController, type: :controller do
  render_views

  before(:each) { @procedure = create(:procedure) }

  #### common values
  model = Procedure
  factory_model = :procedure
  models_name = 'procedures'
  can_archive = true
  #### values for edit
  model_edit_path = '/'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for destroy
  model_delete_path = '/environment/metadata/procedures'

  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)
  it_should_behave_like 'status of objects controller', factory_model, models_name

  context '#load_tab_data' do
    it 'return step' do
      step = create(:step, procedure: @procedure)

      get :load_tab_data, { id: @procedure.id,
                            step_id: step.id,
                            format: 'js' }
      expect(assigns(:step)).to eq step
    end

    it 'builds step' do
      get :load_tab_data, { id: @procedure.id,
                            format: 'js' }

      expect(assigns(:step)).to_not be_nil
      expect(assigns(:procedure)).to eq @procedure
    end
  end

  describe '#index' do
    it 'assigns procedures and renders template' do
      per_page = 1
      archived_procedures = create_list(:procedure, 3)
      archived_procedures = archived_procedures.each(&:archive).sort_by(&:name)
      paginated_archived_procedures = archived_procedures[0...per_page]

      get :index, page: 1, per_page: per_page

      expect(assigns(:procedures)).to include(@procedure)
      expect(assigns(:archived_procedures)).to match_array paginated_archived_procedures
      expect(response).to render_template('index')
    end
  end

  context '#create' do
    before(:each) do
      @app = create(:app)
      @req = create(:request)
      @params = { request_id: @req.id,
                  app_ids: [@app.id],
                  procedure: { name: 'proc1' },
                  format: 'js' }
    end

    it 'fails without steps' do
      post :create, @params
      expect(flash[:error]).to include('At least one enabled')
    end

    it 'fails with all request steps' do
      new_procedure = Procedure.new
      create(:step, request: @req)
      Procedure.stub(:new).and_return(new_procedure)
      new_procedure.stub(:save).and_return(false)

      post :create, @params

      expect(response).to render_template('misc/error_messages_for')
    end

    it 'success with checked steps of request' do
      step = create(:step, request: @req)
      Procedure.stub(:new).and_return(@procedure)
      @procedure.stub(:save).and_return(true)

      post :create, { request_id: @req.id,
                      app_ids: [@app.id],
                      format: 'js',
                      procedure: { name: 'proc_new',
                                   step_ids: [step.id.to_s] }}

      expect(flash[:success]).to include('successfully')
      expect(response).to render_template('misc/redirect')
    end

    it 'assigns creator' do
      step = create(:step)

      post :create, procedure: { name: 'New Procedure', step_ids: [step.id] }

      expect(assigns(:procedure).created_by).to eq @user.id
    end

    it_behaves_like 'authorizable', controller_action: :create,
                                    ability_action: :create,
                                    subject: Request
  end

  context '#new procedure template' do
    before(:each) { @app = create(:app) }

    it 'success' do
      post :new_procedure_template, { app_ids: [@app.id],
                                      procedure: { name: 'proc1' }}

      expect(flash[:success]).to include('successfully')
      expect(response.code).to eq '302'
    end

    it 'fails' do
      new_procedure = Procedure.new
      Procedure.stub(:new).and_return(new_procedure)
      new_procedure.stub(:save).and_return(false)

      post :new_procedure_template, { app_ids: [@app.id],
                                      procedure: { name: 'proc1' }}

      expect(response).to render_template('new')
    end
  end

  context '#update' do
    it 'success' do
      put :update, { id: @procedure.id,
                     procedure: { name: 'Procedure_changed' }}

      @procedure.reload
      expect(@procedure.name).to eq 'Procedure_changed'
      expect(flash[:success]).to include('successfully')
      expect(response).to redirect_to(procedures_path)
    end

    it 'fails' do
      Procedure.stub(:find).and_return(@procedure)
      @procedure.stub(:update_attributes).and_return(false)

      put :update, { id: @procedure.id,
                     procedure: { name: 'Procedure_changed' }}

      expect(flash[:error]).to include('problem')
      expect(response).to render_template('edit')
    end
  end

  it '#update_step_position' do
    #TODO remove stub and add code for creating list and adding step to procedure
    step = create(:step, insertion_point: 1)
    Procedure.stub(:find).and_return(@procedure)
    @procedure.steps.stub(:find).and_return(step)

    put :update_step_position, { id: step.id,
                                 procedure_id: @procedure.id,
                                 step: { insertion_point: 2 }}
    step.reload
    expect(step.insertion_point).to eq 2
    expect(response).to render_template(partial: 'procedures/_step_for_reorder')
  end

  it '#show' do
    get :show, id: @procedure.id

    expect(response).to redirect_to(edit_procedure_path(@procedure.id))
  end

  it '#reorder_steps' do
    get :reorder_steps, id: @procedure.id

    expect(assigns(:procedure)).to eq @procedure
    expect(response).to render_template('_reorder_steps')
  end

  context '#add_to_request' do
    it 'from request' do
      request = create(:request)
      post :add_to_request, { id: @procedure.id,
                              request_id: request.number,
                              from_request: true }
      expect(response).to redirect_to(edit_request_path(request))
    end

    it 'not from request' do
      request = create(:request)
      post :add_to_request, { id: @procedure.id,
                              request_id: request.number,
                              from_request: false }
      expect(response).to render_template(partial: 'steps/_procedure_for_reorder')
    end
  end

  it '#get_procedure_step_section' do
    get :get_procedure_step_section, { id: create(:step).id, preview: true }

    expect(response).to render_template(partial: 'steps/_procedure_step_section')
  end
end
