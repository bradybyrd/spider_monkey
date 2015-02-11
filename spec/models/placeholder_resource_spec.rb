require 'spec_helper'

describe PlaceholderResource do
  before(:each) do
    @placeholder_resource = PlaceholderResource.new
  end

  it 'should have the scopes' do
    PlaceholderResource.should respond_to(:managed_by)
  end

  describe '#methods' do
    it { @placeholder_resource.last_name.should == 'Placeholder' }
    it { @placeholder_resource.password_required?.should_not be_truthy }
    it { @placeholder_resource.system_user?.should_not be_truthy }
  end
end
