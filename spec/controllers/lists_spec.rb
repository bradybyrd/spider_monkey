require 'spec_helper'

describe ListsController, type: :controller do
  before(:each) { @list = create(:list) }

  #### common values
  model = List
  factory_model = :list
  can_archive = true
  #### values for index
  models_name = 'lists'
  model_index_path = 'index'
  be_sort = true
  per_page = 20
  index_flash = 'No List'
  #### values for edit
  model_edit_path = '/environment/metadata/lists'
  edit_flash = nil
  http_refer = nil
  #### values for destroy
  model_delete_path = '/environment/metadata/lists'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  context '#create' do
    it 'success' do
      expect{ post :create, { list: { name: 'List1',
                                      is_text: 'true' }}
            }.to change(List, :count).by(1)
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(lists_path)
    end
  end

  context '#update' do
    it 'text list success' do
      expect{ put :update, { id: @list.id,
                             list: { name: 'LS1' },
                             active_list_items: '1,00_2',
                             inactive_list_items: '3,4'}
            }.to change(ListItem, :count).by(1)
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(lists_path)
    end

    it 'number list success' do
      list2 = create(:list, is_text: false)

      expect{put :update, { id: list2.id,
                            list: { name: 'LS1' },
                            active_list_items: '1,00_2',
                            inactive_list_items: '3,4'}
            }.to change(ListItem, :count).by(1)
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(lists_path)
    end

    context 'bad scenarios' do
      before(:each) do
        List.any_instance.stub(:update_attributes).and_return(false)
        List.stub(:find).and_return(@list)
      end

        it 'fails' do
          @list.stub(:update_attributes).and_return(false)

          put :update, { id: @list.id }

          expect(flash[:error]).to include('errors')
          expect(response).to redirect_to(lists_path)
        end

        it 'return error when item invalid' do
          # pending "method doesn`t work correctly"
          put :update, { id: @list.id,
                         list: { name: 'LS1' },
                         active_list_items: '1,00_qwerty',
                         inactive_list_items: '3,4'}

          expect(flash[:error]).to include('validation errors')
          expect(response).to redirect_to(lists_path)
        end

      after(:each) do
        List.any_instance.unstub(:update_attributes)
        List.unstub(:find)
      end
    end
  end
end
