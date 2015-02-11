require 'spec_helper'

describe GroupsController do
  let(:group) { create(:group) }

  context 'shared examples' do
    #### common values
    model_name =  Group
    factory_model =  :group
    can_archive =  false

    #### values for index
    models_name =  'groups'
    model_index_path =  '_index'
    be_sort =  true
    per_page =  30
    index_flash = I18n.t(:'activerecord.notices.not_found', model: I18n.t('activerecord.models.group'))

    #### values for edit
    model_edit_path =  '/groups'
    edit_flash =  nil
    http_refer =  nil

    #### values for create
    model_create_path =  nil
    create_params =  {group: {name: 'name_changed', role_ids: ''}}

    #### values for destroy
    model_delete_path =  '/groups'

    it_should_behave_like('CRUD GET index', model_name, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
    it_should_behave_like('CRUD GET new')
    it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
    it_should_behave_like('CRUD POST create', model_name, factory_model, model_create_path, create_params)
  end

  context '#update' do
    it 'success' do
      put :update, {id: group.id,
                    group: {name: 'Group_changed',
                            resource_ids: [@user.id],
                            role_ids: ''}}
      Group.find(group.id).name.should eql('Group_changed')
      flash[:success].should include('successfully')
      response.should redirect_to(groups_path)
    end

    it 'unsuccess' do
      put :update, { id: group.id,
                     group: { name: '',
                              resource_ids: [@user.id],
                              role_ids: '' }}
      assigns(:unmanaged_users).should include(@user)
      response.should render_template('edit')
    end
  end

  it '#set_default' do
    put :set_default, {id: group.id}
    group.reload
    group.position.should eql(1)
    flash[:success].should include('successfully')
    response.should redirect_to(groups_path)
  end

  context '#deactivate' do
    it 'redirects to groups list if unable to make group inactive' do
      Group.any_instance.stub(:deactivate!).and_return(false)

      put :deactivate, id: create(:group, active: false)
      expect(flash[:error]).to eq I18n.t('group.deactivate_error')
      expect(response).to redirect_to groups_path
    end
  end

  context '#default_group', custom_roles: true do
    it 'set default group for user' do
      @group = create(:group)
      @user = create(:user, groups: [@group])
      @role = create(:role)
      @default_group = create(:group, position: 1, name: '[default]')
      expect{
        put :update, {id: @group.id, group: { resource_ids: [], role_ids: @role.id }}
      }.to change{@default_group.user_ids.count}.from(0).to(1)
    end
  end
end
