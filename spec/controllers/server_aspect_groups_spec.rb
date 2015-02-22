require 'spec_helper'

describe ServerAspectGroupsController, type: :controller do
  before(:each) { @aspect_group = create(:server_aspect_group) }

  describe 'authorization', custom_roles: true do
    context 'with no permissions' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :list, ServerAspectGroup
        specify { get :index }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, ServerAspectGroup
        specify { get :new }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, ServerAspectGroup
        specify { get :edit, id: @aspect_group }
      end
    end
  end

  context '#index' do
    it "return flash 'No Aspect Groups'" do
      ServerAspectGroup.delete_all

      get :index

      expect(flash[:error]).to include('No Server Level Groups')
    end

    context 'find records' do
      it 'render partial' do
        get :index, render_no_rjs: true

        expect(response).to render_template(partial: '_index')
      end

      specify 'without keyword' do
        get :index

        expect(assigns(:server_aspect_groups)).to include(@aspect_group)
        expect(response).to render_template('index')
      end

      specify 'with keyword' do
        server_aspect_groups =
            31.times.collect{ |x| create(:server_aspect_group, name: "Dev#{x}") }
        server_aspect_groups.sort_by!{|el| el.name}

        get :index, key: 'Dev'

        groups = assigns(:server_aspect_groups)
        server_aspect_groups[0..29].each{|el| expect(groups).to include(el)}
        expect(groups).to_not include(server_aspect_groups[30])
        expect(groups).to_not include(@aspect_group)
      end
    end
  end

  it '#new' do
    xhr :get, :new
    expect(response).to render_template('server_aspect_groups/load_form')
  end

  describe '#create' do
    it 'renders save' do
      xhr :post, :create, server_aspect_group: { name: 'new aspect group' }
      is_expected.to render_template(:save)
    end

    it 'renders form' do
      xhr :post, :create
      is_expected.to render_template(:form)
    end

    it 'creates record' do
      expect {
        xhr :post, :create, server_aspect_group: { name: 'new aspect group' }
      }.to change(ServerAspectGroup, :count).by(1)
    end
  end

  it '#edit' do
    xhr :get, :edit, id: @aspect_group.id
    expect(response).to render_template('server_aspect_groups/load_form')
  end

  describe '#update' do
    it 'renders save' do
      xhr :put, :update, id: @aspect_group, server_aspect_group: { name: 'updated aspect group' }
      is_expected.to render_template(:save)
    end

    it 'renders form' do
      xhr :put, :update, id: @aspect_group, server_aspect_group: { name: '' }
      is_expected.to render_template(:load_form)
    end

    it 'updates record' do
      xhr :put, :update, id: @aspect_group, server_aspect_group: { name: 'updated aspect group' }
      expect(@aspect_group.reload.name).to eq 'updated aspect group'
    end
  end

  it '#server_aspect_options' do
    server_level = create(:server_level)
    get :server_aspect_options, {:server_aspect_group => {:server_level_id => server_level.id}}
    expect(response.code).to eq '200'
  end
end
