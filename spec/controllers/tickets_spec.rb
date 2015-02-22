require 'spec_helper'

describe TicketsController, type: :controller do
  before(:each) do
    @project_server = create(:project_server)
    @ticket = create(:ticket, :project_server => @project_server)
  end

  describe 'authorization', custom_roles: true do
    context 'authorization fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :list, Ticket
        specify { get :index }

        context 'from plans' do
          include_context 'mocked abilities', :cannot, :list_plan_tickets, Ticket
          specify { get :index, id: create(:plan) }
        end
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Ticket
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Ticket
        specify { post :create }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Ticket
        specify { get :edit, id: @ticket }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Ticket
        specify { put :update, id: @ticket }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, Ticket
        specify { delete :destroy, id: @ticket }
      end
    end
  end

  context '#index' do
    it 'renders template index' do
      get :index
      expect(response).to render_template('index')
    end

    it 'render partial tickets_list' do
      xhr :get, :index
      expect(response).to render_template(partial: 'tickets/_tickets_list')
    end

    it 'returns paginated records' do
      Ticket.delete_all
      tickets = 21.times.collect{ create(:ticket, project_server: create(:project_server)) }
      tickets.sort_by!{ |el| el.name }
      tickets.reverse!

      get :index

      tickets[0..19].each { |el| expect(assigns(:tickets)).to include(el)}
      expect(assigns(:tickets)).to_not include(tickets[20])
    end

    it 'returns records with keyword' do
      ticket2 = create(:ticket, project_server: create(:project_server),
                                name: 'Dev1')
      get :index, key: 'Dev'

      expect(assigns(:tickets)).to include(ticket2)
      expect(assigns(:tickets)).to_not include(@ticket)
    end

    it "renders partial 'tickets/unpaged_tickets_table'" do
      get :index, { filters: { sort_scope: 'false' },
                    actions: 'unpaged' }
      expect(response).to render_template(partial: 'tickets/_unpaged_tickets_table')
    end

    it 'renders template select_tickets_list' do
      xhr :get, :index, { filters: { plan_association: 'Selected' },
                          current_tickets: "#{@ticket.id}",
                          actions: 'select',
                          format: 'js',
                          step_facebox: true }
      expect(response).to render_template('tickets/select_tickets_list')
    end

    it 'renders partial select_tickets_list_in_facebox' do
      xhr :get, :index, { filters: { plan_association: 'Unselected' },
                          current_tickets: "#{@ticket.id}",
                          actions: 'select' }
      expect(response).to render_template(partial: 'tickets/_select_tickets_list_in_facebox')
    end

    it 'renders partial select_tickets_list_in_facebox without filter params' do
      xhr :get, :index, { current_tickets: @ticket.id.to_s,
                          actions: 'select'}
      expect(response).to render_template(partial: 'tickets/_select_tickets_list_in_facebox')
    end

    it 'renders template plans/show with plan_id' do
      plan = create(:plan)

      get :index, { filters: {plan_id: plan.id} }

      expect(response).to render_template('plans/show')
    end

    it 'renders partial ticket_list with plan_id' do
      plan = create(:plan)

      xhr :get, :index, { filters: { plan_id: plan.id }}

      expect(response).to render_template(partial: 'tickets/_tickets_list')
    end
  end

  context 'new' do
    it 'renders template new' do
      get :new, { project_server_id: @project_server.id }
      expect(response).to render_template('new')
    end

    it 'renders partial' do
      xhr :get, :new
      expect(response).to render_template(partial: 'tickets/_form')
    end
  end

  context '#edit' do
    it 'renders template edit' do
      get :edit, id: @ticket.id
      expect(response).to render_template('edit')
    end

    it 'renders partial' do
      xhr :get, :edit, { id: @ticket.id,
                         project_server_id: @project_server.id }
      expect(response).to render_template(partial: 'tickets/_form')
    end

    it 'returns flash error and redirects' do
      get :edit, id: '-1'
      expect(flash[:error]).to include('does not exist')
      expect(response).to redirect_to root_path
    end
  end

  context '#create' do
    it 'success' do
      expect{
        post :create, { ticket: { project_server_id: @project_server.id,
                                  foreign_id: 'Ticket1',
                                  name: 'this is Ticket1' }}
      }.to change(Ticket, :count).by(1)
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to tickets_path
    end

    it 'fails' do
      Ticket.stub(:new).and_return(@ticket)
      @ticket.stub(:save).and_return(false)

      post :create, { ticket: { project_server_id: @project_server.id,
                                foreign_id: 'Ticket1',
                                name: 'this is Ticket1' }}
      expect(response).to render_template('new')
    end
  end

  context '#update' do
    before(:each) do
      @params = { id: @ticket.id,
                  ticket: { project_server_id: @project_server.id,
                            foreign_id: 'Ticket1',
                            name: 'Changed' }}
    end

    it 'success' do
      put :update, @params

      @ticket.reload
      expect(@ticket.name).to eq 'Changed'
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(tickets_path)
    end

    it 'fails' do
      Ticket.stub(:find).and_return(@ticket)
      @ticket.stub(:update_attributes).and_return(false)

      put :update, @params

      expect(response).to render_template('edit')
    end
  end

  context '#destroy' do
    it 'renders template destroy_ticket' do
      expect{
        xhr :delete, :destroy, id: @ticket.id
      }.to change(Ticket, :count).by(-1)
      expect(response).to render_template('tickets/destroy_ticket' )
    end

    it 'redirects to tickets_plan_path' do
      plan = create(:plan)

      expect{
        delete :destroy, { id: @ticket.id, plan_id: plan.id }
      }.to change(Ticket, :count).by(-1)
      expect(response).to redirect_to(tickets_plan_path(plan.id))
    end

    it 'redirects to tickets_path' do
      expect{
        delete :destroy, id: @ticket.id
      }.to change(Ticket, :count).by(-1)
      expect(response).to redirect_to(tickets_path)
    end
  end

  it '#query' do
    #TODO check return data
    plan = create(:plan)

    xhr :get, :query, :plan_id => plan.id

    expect(response).to render_template(partial: 'tickets/_query')
  end

  context '#resource_automations' do
    before(:each) do
      script_content = <<-'SCRIPT_CONTENT'
                      ### <u>def execute(script_params, parent_id, offset, max_records)</u>
                      # argument1:
                      #   name: the first argument
                      # argument2:
                      #   name: the second argument
                      ###
                      echo 1
                      #Close the file
                      @hand.close
                            SCRIPT_CONTENT
      @plan = create(:plan)
      @project_server = create(:project_server)
      @script = create(:general_script, automation_type: 'ResourceAutomation',
                                        unique_identifier: 'some id',
                                        content: script_content,
                                        maps_to: 'Ticket')
      @project_server.scripts << @script
    end

    it 'renders partial' do
      xhr :get, :resource_automations, { plan_id: @plan.id,
                                         project_server_id: @project_server.id }
      expect(response).to render_template(partial: 'tickets/_resource_automations')
    end

    it 'returns error' do
      get :resource_automations, plan_id: @plan.id

      expect(flash.now[:error]).to include('Unable to find resource automations')
    end
  end

  context '#filter_arguments' do
    before(:each) { @script = create(:general_script) }

    specify 'with query' do
      plan = create(:plan)
      project_server = create(:project_server)
      query = plan.queries.create(name: 'Query1', project_server_id: project_server.id)
      query.script = @script
      query.query_details.create
      query.save

      xhr :get, :filter_arguments, {:query_id => query.id}

      expect(response).to render_template(partial: 'tickets/_filter_arguments')
    end

    specify 'with script_id' do
      xhr :get, :filter_arguments, script_id: @script.id

      expect(response).to render_template(partial: 'tickets/_filter_arguments')
    end
  end

  context '#add_selected_external' do
    before(:each) do
      @plan = create(:plan)
      @project_server = create(:project_server)
    end

    it "returns message 'Unable to find' and redirects plans_path" do
      post :add_selected_external

      expect(assigns(:message)).to include('Unable to find a plan')
      expect(response).to redirect_to(plans_path)
    end

    it "returns message 'could not locate any tickets' and redirects tickets_plan_path" do
      post :add_selected_external, { plan_id: @plan.id,
                                     project_server_id: @project_server.id }

      expect(assigns(:message)).to include('could not locate any tickets')
      expect(response).to redirect_to(tickets_plan_path(@plan))
    end

    it "returns message 'Import completed' and redirects tickets_plan_path" do
      Ticket.stub(:add_tickets_to_plan).and_return( double('result').as_null_object )

      post :add_selected_external, { plan_id: @plan.id,
                                     project_server_id: @project_server.id,
                                     argument: {'1' => @ticket},
                                     cached_data: {'1' => @ticket.to_json }}

      expect(assigns(:message)).to include('Import completed')
      expect(response).to redirect_to(tickets_plan_path(@plan))
    end
  end
end
