require 'spec_helper'


describe InstanceReferencesController do

  context "#delete" do
    it "#delete" do

      User.current_user = User.find_by_login("admin")
      default_server = create(:server)
      package = create(:package)
      package_instance = create(:package_instance, package: package, active: true, name: 'test')
      reference = create(:reference, package: package, name: 'test', server: default_server )
      comp1 = create(:instance_reference, server: default_server, package_instance: package_instance, reference: reference)

      expect{delete :destroy, {:id => comp1.id }
      }.to change(InstanceReference, :count).by(-1)

    end
  end


end
