shared_examples 'CRUD GET index', shared: true do |model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash|
  before(:each) do
    model.delete_all
  end

  if can_archive
    it ' it returns valid data with pagination and renders template' do
      archived_models = (per_page+1).times.collect{create(factory_model)}
      archived_models.each{|el| el.archive}
      unarchived_models = (per_page+1).times.collect{create(factory_model)}
      if be_sort
        archived_models.sort_by!{|el| el.name}
        unarchived_models.sort_by!{|el| el.name}
      end
      get :index, {per_page: per_page,
                   page: 1}
      assigns(:"#{models_name}").should_not include(archived_models)
      assigns(:"archived_#{models_name}").should_not include(unarchived_models)
      archived_models[0..per_page-1].each{|el| assigns(:"archived_#{models_name}").should include(el)}
      unarchived_models[0..per_page-1].each{|el| assigns(:"#{models_name}").should include(el)}
      assigns(:"#{models_name}").should_not include(unarchived_models[per_page])
      assigns(:"archived_#{models_name}").should_not include(archived_models[per_page])
      expect(response).to render_template(model_index_path)
    end
  else
    it 'renders partial with xhr request' do
      xhr :get, :index
      expect(response).to render_template(partial: model_index_path)
    end

    it 'returns flash no elements' do
      get :index
      expect(flash[:error]).to include(index_flash)
    end

    context 'returns valid data' do
      before(:each) do
        @active_models = (per_page+1).times.collect{create(factory_model)}
        if be_sort
          @active_models.sort_by!{|el| el.name}
        end
      end

      it 'with pagination and renders template' do
        get :index, {per_page: per_page,
                     page: 0}
        @active_models[0..per_page-1].each{|el| assigns(:"active_#{models_name}").should include(el)}
        assigns(:"active_#{models_name}").should_not include(@active_models[per_page])
        expect(response).to render_template('index')
      end

      it 'with keyword' do
        @active_models[0..9].each_with_index{|el, i| el.update_attributes(name: "Dev#{i}")}
        inactive_model1 = create(factory_model, name: 'Dev1_1', active: 'false')
        inactive_model2 = create(factory_model, active: 'false')
        get :index, {key: 'Dev'}
        @active_models[0..9].each{|el| assigns(:"active_#{models_name}").should include(el)}
        @active_models[10..19].each{|el| assigns(:"active_#{models_name}").should_not include(el)}
        assigns(:"inactive_#{models_name}").should include(inactive_model1)
        assigns(:"inactive_#{models_name}").should_not include(inactive_model2)
      end
    end
  end
end

shared_examples 'CRUD GET new', shared: true do
  it 'renders template' do
    get :new
    expect(response).to render_template('new')
  end
end

shared_examples 'CRUD GET edit', shared: true do |factory_model, model_edit_path, edit_flash, http_refer|
  it 'renders template' do
    get :edit, id: create(factory_model).id
    expect(response).to render_template('edit')
  end

  it 'not founds record' do
    if http_refer
      @request.env['HTTP_REFERER'] = '/index'
    end
    if edit_flash.nil?
      expect{get :edit, id: '-1'}.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to be_success
    else
      get :edit, id: '-1'
      expect(flash[:error]).to include(edit_flash)
      expect(response).to redirect_to(model_edit_path)
    end
  end
end

shared_examples 'CRUD POST create', shared: true do |model, factory_model, model_create_path, create_params|
  it 'creates new element' do
    post :create, create_params
    expect(flash[:notice]).to include('successfully') if flash[:notice]
    expect(flash[:success]).to include('successfully') if flash[:success]
    if model_create_path.nil?
      expect(response.code).to eql('302')
    else
      expect(response).to redirect_to(model_create_path)
    end
  end

  it 'fails creation' do
    @model = create(factory_model)
    model.stub(:new).and_return(@model)
    @model.stub(:save).and_return(false)
    post :create
    expect(response).to render_template('new')
  end
end

shared_examples 'CRUD PUT update', shared: true do |model, factory_model, update_params|
  it 'changes attributes' do
    @model = create(factory_model)
    put :update, id: @model.id, factory_model => update_params
    @model.reload
    expect(@model.name).to eql(update_params[:name])
    expect(flash[:notice]).to include('successfully')
    expect(response.code).to eql('302')
  end

  it 'fails changing attributes' do
    @model = create(factory_model)
    model.stub(:find).and_return(@model)
    @model.stub(:update_attributes).and_return(false)
    put :update, id: @model.id, factory_model => update_params
    expect(response).to render_template('edit')
  end
end

shared_examples 'CRUD DELETE destroy', shared: true do |model, factory_model, model_delete_path, can_archive|
  it 'deletes record and redirects' do
    if can_archive
      @model = create(factory_model)
      @model.archive
    else
      @model = create(factory_model, active: false)
    end
    expect{delete :destroy, id: @model.id}.to change(model, :count).by(-1)
    expect(response).to redirect_to(model_delete_path)
  end
end
