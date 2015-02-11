require 'spec_helper'

describe ActivityDeliverable do
  before(:each) do
    @activity_deliverable = create(:activity_deliverable)
  end

  describe 'validations' do
    it { @activity_deliverable.should validate_presence_of(:name) }
    it { @activity_deliverable.should validate_presence_of(:activity_id) }
    context 'for release_deployment' do
      before(:each) { @activity_deliverable2 = create(:activity_deliverable, :release_deployment => true) }
      it { @activity_deliverable2.should validate_presence_of(:projected_delivery_on) }
      it { @activity_deliverable2.should validate_presence_of(:deployment_contact_id) }
    end
  end

  describe 'associations' do
    context 'belong to' do
      it { @activity_deliverable.should belong_to(:activity) }
      it { @activity_deliverable.should belong_to(:activity_phase) }
      it { @activity_deliverable.should belong_to(:deployment_contact) }
    end

    context 'have many' do
      it { @activity_deliverable.should have_many(:activity_attribute_values) }
    end
  end

  describe 'callbacks' do
    it 'should run the proper callback before save' do
      @activity_deliverable.should_receive(:delete_custom_attrs)
      @activity_deliverable.send(:save)
    end
    it 'should run the proper callback after save' do
      @activity_deliverable.should_receive(:save_custom_attrs)
      @activity_deliverable.send(:save)
    end
    it 'should run the proper validation callbacks before save' do
      @activity_deliverable.should_receive(:validate_projected_delivery_on)
      @activity_deliverable.should_receive(:phase_has_start_and_end)
      @activity_deliverable.should_receive(:custom_attrs_validations)
      @activity_deliverable.send(:save)
    end
  end
end
