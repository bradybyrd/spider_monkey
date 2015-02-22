require 'spec_helper'

describe ReferencesController do
  describe 'authorization', custom_roles: true do
    context 'fails' do
      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Reference
        specify do
          get :new, package_id: create(:package)
          should redirect_to root_path
        end
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Reference
        specify do
          post :create, package_id: create(:package)
          should redirect_to root_path
        end
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Reference
        specify do
          reference = create(:reference)
          get :edit, package_id: reference.package, id: reference
          should redirect_to root_path
        end
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Reference
        specify do
          reference = create(:reference)
          put :update, package_id: reference.package, id: reference
          should redirect_to root_path
        end
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, Reference
        specify do
          reference = create(:reference)
          delete :destroy, package_id: reference.package, id: reference
          should redirect_to root_path
        end
      end
    end
  end

  context '#delete' do
    it 'delete a reference from the package' do
      User.current_user = User.find_by_login('admin')
      default_server = create(:server)
      package = create(:package)
      create(:package_instance, package: package, active: true, name: 'test')
      reference = create(:reference, package: package, name: 'test', server: default_server )

      expect{ delete :destroy, {:id => reference.id }
            }.to change(Reference, :count).by(-1)
    end
  end
end