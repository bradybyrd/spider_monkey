require 'spec_helper'

describe ListItemsController, type: :controller do
  context '#create' do
    it 'text item whithout value' do
      list = create(:list, is_text: true)

      put :create, { list_id: list.id,
                     value: '  '}

      expect(response.body).to include('name not allowed to be empty')
    end

    it 'number item whithout value' do
      list2 = create(:list, is_text: false)

      put :create, {:list_id => list2.id,
                    :value => '  '}

      expect(response.body).to include('name not allowed to be empty')
    end
  end
end
