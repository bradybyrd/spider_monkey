require 'spec_helper'

describe InstanceReference do

  context '' do
    before(:each) do
      User.current_user = User.find_by_login("admin")
      default_server = create(:server)

      package = create(:package)
      package_instance = create(:package_instance, package: package, active: true, name: 'test')

      reference = create(:reference, package: package, name: 'test', server: default_server )

      @comp1 = create(:instance_reference, server: default_server, package_instance: package_instance, reference: reference)
    end

    describe "validations" do
      it { @comp1.should validate_presence_of(:name) }
      it { @comp1.should validate_presence_of(:uri) }
      it { @comp1.should validate_presence_of(:server) }
      it { should ensure_inclusion_of(:resource_method).in_array(%w(File)) }
    end

    describe "associations" do
      it "should belong to" do
        @comp1.should belong_to(:reference)
        @comp1.should belong_to(:server)
      end

      it "should have" do
        @comp1.should  have_many(:properties).through(:property_values)
      end
    end
  end



end

