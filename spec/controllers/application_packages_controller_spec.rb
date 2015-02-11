require 'spec_helper'

describe ApplicationPackagesController do
  describe 'authorization', custom_roles: true do
    context 'fails' do
      describe '#update_all' do
        include_context 'mocked abilities', :cannot, :add_remove_package, App
        specify do
          put :update_all, app_id: create(:app)
          should redirect_to root_path
        end
      end

      describe '#edit_property_values' do
        include_context 'mocked abilities', :cannot, :edit_properties, ApplicationPackage
        specify do
          get :edit_property_values, id: create(:application_package)
          should redirect_to root_path
        end
      end

      describe '#edit_property_values' do
        include_context 'mocked abilities', :cannot, :edit_properties, ApplicationPackage
        specify do
          put :update_property_values, id: create(:application_package)
          should redirect_to root_path
        end
      end
    end
  end
end
