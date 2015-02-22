require 'spec_helper'

describe RequestTemplatesController, type: :controller do

  it_should_behave_like 'status of objects controller', :request_template, 'request_templates'

  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @request1 = create(:request)
    @request1.apps << @app
    @request1.environment = @env
    @request_template = create(:request_template, request: @request1)
  end

  context '#index' do
    before(:each) do
      RequestTemplate.delete_all
      @request_templates = 16.times.collect{create(:request_template, request: @request1)}
      @archived_request_templates = 16.times.collect{create(:request_template, request: @request1)}
      @archived_request_templates.each {|el| el.archive}
      @request_templates.sort_by! {|el| el.name}
    end

    it "returns flash error 'No request template'" do
      RequestTemplate.delete_all

      get :index

      expect(flash[:error]).to include('No request template')
      expect(response).to render_template('index')
    end

    it 'returns records with keyword and numeric pagination' do
      request_template1 = create(:request_template, name: 'without key1', request: @request1)
      request_template1.save

      get :index, {key: 'Template',
                   request: {id: @request1.id},
                   numeric_pagination: true}

      active_requests = assigns(:request_templates)
      @request_templates[0..14].each{|el| expect(active_requests).to include(el)}
      @archived_request_templates.each{|el| assigns(:inactive_request_templates).should include(el)}
      expect(active_requests).to_not include(request_template1)
      expect(active_requests).to_not include(@request_templates[15])
    end

    it 'returns request templates which are not in draft state' do
      request_template1 = create(:request_template, name: 'without key1', aasm_state: 'draft', request: @request1)

      xhr :get, :index, {numeric_pagination: 'true', visible_only: 'true'}

      active_requests = assigns(:request_templates)
      @request_templates[0..14].each{ |el| expect(active_requests).to include(el) }
      expect(active_requests).to_not include(request_template1)
      expect(active_requests).to_not include(@request_templates[15])
    end

    it 'renders partial ajax_pagination_index' do
      xhr :get, :index

      expect(response).to render_template(partial: 'request_templates/_ajax_pagination_index')
    end

    it 'renders partial list' do
      xhr :get, :index, {numeric_pagination: true}

      expect(response).to render_template(partial: 'request_templates/_list')
    end
  end

  context '#details' do
    before(:each) do
      RequestTemplate.delete_all
      @request_templates = 17.times.collect{create(:request_template, request: @request1)}
    end

    it 'returns records with keyword and numeric pagination' do
      pending 'This is phantom test'
      req = @request_templates[0]
      req.name = 'without key1'
      req.save
      @request_templates.sort_by!{|el| el.name}

      get :details, {key: 'Template',
                     per_page: 15,
                     request: { id: @request1.id },
                     position: 'unarchived',
                     numeric_pagination: true}

      active_requests = assigns(:request_templates)
      @request_templates[0..14].each{|el| expect(active_requests).to include(el)}
      expect(active_requests).to_not include(req)
      expect(active_requests).to_not include(@request_templates[16])
    end

    it 'returns ordered records with alphabetical pagination' do
      request_templates = 16.times.collect{create(:request_template, request: @request1)}
      request_templates.each {|el| el.archive}
      request_templates.sort_by!{|el| el.name}

      get :details, {per_page: 15, order: {'0' => [:name, 'ASC'] }}

      active_requests = assigns(:request_templates)
      request_templates[0..14].each{|el| expect(active_requests).to include(el)}
      expect(active_requests).to_not include(request_templates[15])
      expect(response).to render_template(partial: 'request_templates/_details')
    end
  end

  context '#create' do
    it 'success' do
      xhr :post, :create, { request_id: @request1.number,
                            request_template: { name: 'ReqTemplate1' }}

      expect(flash[:success]).to include('successfully')
      expect(response).to render_template('misc/redirect')
    end

    context 'fails' do
      before(:each) do
        @request_template = create(:request_template, request: @request1)
        RequestTemplate.stub(:initialize_from_request).and_return(@request_template)
        @request_template.stub(:save).and_return(false)
      end

      it 'renders template create' do
        xhr :post, :create, {request_id: @request1.number,
                             request_template: {name: 'ReqTemplate1'}}

        expect(response).to render_template('request_templates/create')
      end

      it 'redirects to edit request path and returns flash error' do
        post :create, {request_id: @request1.number,
                       request_template: {name: 'ReqTemplate1'}}

        expect(flash[:error]).to include('problem creating')
        expect(response).to redirect_to(edit_request_path(@request1))
      end
    end

    it_behaves_like 'authorizable', ability_action: :create_template,
                                    type: :xhr,
                                    subject: Request,
                                    http_method: :post,
                                    controller_action: :create do
      let(:params) { { request_id: @request1.number,
                       request_template: { name: 'ReqTemplate1' } } }
    end
  end

  it '#destroy' do
    @request_template.archive

    expect{ delete :destroy, {id: @request_template.id}
          }.to change(RequestTemplate, :count).by(-1)
    expect(response).to redirect_to(request_templates_path)
  end

  it '#create_variant' do
    get :create_variant, request_id: @request1.number

    expect(response).to render_template('create_variant')
  end

  it '#save_variant' do
    @team = create(:team)

    post :save_variant, { request_id: @request1.number,
                          request_template_id: @request_template.id,
                          team_name: 'Team_name',
                          teams: [@team.id] }
    expect(response).to redirect_to(edit_request_path(@request1))
  end

  context '#update' do
    it 'success' do
      RequestTemplate.any_instance.stub(:request).and_return(@request1)

      put :update, { id: @request_template.id,
                     request_template: { name: 'Changed' }}

      expect(flash[:notice]).to include('successfully')
      @request_template.reload
      expect(@request_template.name).to eq 'Changed'
      expect(response).to redirect_to(@request_template.request)
    end

    it 'fails' do
      RequestTemplate.stub(:find).and_return(@request_template)
      @request_template.stub(:update_attributes).and_return(false)

      put :update, { id: @request_template.id,
                     request_template: { name: 'Changed' }}

      expect(flash[:notice]).to be_nil
      expect(response).to redirect_to(@request_template.request)
    end
  end

  it '#show' do
    get :show, request_id: @request1.id
    expect(response).to render_template('show')
  end

  context '#request_template_warning' do
    it 'renders state usage warning' do
      xhr :get, :request_template_warning, id: @request_template.id
      expect(response).to render_template('object_state/_state_usage_warning')
    end

    it 'has type request_template' do
      xhr :get, :request_template_warning, id: @request_template.id
      expect(assigns(:type)).to eql('request_template')
    end

    it 'returns no warning for released template' do
      xhr :get, :request_template_warning, id: @request_template.id
      expect(assigns(:warning)).to be_falsey
    end

    it 'returns warning for pending template' do
      @request_template.update_attributes(aasm_state: 'pending')
      xhr :get, :request_template_warning, id: @request_template.id
      expect(assigns(:warning)).to include(@request_template.warning_state)
    end

    it 'returns warning for retired template' do
      @request_template.update_attributes(aasm_state: 'retired')
      xhr :get, :request_template_warning, id: @request_template.id
      expect(assigns(:warning)).to include(@request_template.warning_state)
    end

    it 'returns no warning for Undefined' do
      xhr :get, :request_template_warning, id: '0'
      expect(assigns(:warning)).to be_falsey
    end
  end
end