require "spec_helper"

describe BladelogicUser do
  before(:each) do
    @bladelogic_user = BladelogicUser.new
  end

  let(:BladelogicUser_with_SharedCript) {
    BladelogicUser.new do
      include BladelogicUser::SharedScript
    end
  }

  it "should have associations" do
    @bladelogic_user.should belong_to(:streamdeploy_user)
    @bladelogic_user.should have_many(:roles)
  end
end
