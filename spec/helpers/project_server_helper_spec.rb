require "spec_helper"

describe ProjectServersHelper do
  describe '#can_manage_project?' do
    it 'returns true if user can create' do
      integration_project = double :integration_project
      helper.stub(:can?).with(:create, integration_project).and_return true
      helper.stub(:can?).with(:make_active_inactive, integration_project).and_return false
      helper.stub(:can?).with(:edit, integration_project).and_return false

      expect(helper.can_manage_project?(integration_project)).to eq true
    end

    it 'returns true if user can edit' do
      integration_project = double :integration_project
      helper.stub(:can?).with(:create, integration_project).and_return false
      helper.stub(:can?).with(:make_active_inactive, integration_project).and_return false
      helper.stub(:can?).with(:edit, integration_project).and_return true

      expect(helper.can_manage_project?(integration_project)).to eq true
    end

    it 'returns true if user can make_active_inactive' do
      integration_project = double :integration_project
      helper.stub(:can?).with(:create, integration_project).and_return false
      helper.stub(:can?).with(:edit, integration_project).and_return false
      helper.stub(:can?).with(:make_active_inactive, integration_project).and_return true

      expect(helper.can_manage_project?(integration_project)).to eq true
    end

    it 'returns false in other cases' do
      integration_project = double :integration_project
      helper.stub(:can?).with(:create, integration_project).and_return false
      helper.stub(:can?).with(:edit, integration_project).and_return false
      helper.stub(:can?).with(:make_active_inactive, integration_project).and_return false

      expect(helper.can_manage_project?(integration_project)).to eq false
    end
  end
end