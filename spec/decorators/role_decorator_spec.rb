require 'spec_helper'

describe RoleDecorator do

  describe '#group_expandable_links' do
    let(:object){ double 'Role' }
    subject(:decorator){ RoleDecorator.new(object) }

    it 'calls ApplicationDecorator#association_expandable_links with #group_links' do
      group_links = double('Group links')
      expect(decorator).to receive(:group_links).and_return(group_links)

      association_expandable_links = double('Association expandable links')
      expect(decorator).to receive(:association_expandable_links).with(group_links).and_return(association_expandable_links)

      expect(decorator.group_expandable_links).to eq(association_expandable_links)
    end
  end

  describe '#team_expandable_links' do
    let(:object){ double 'Role' }
    subject(:decorator){ RoleDecorator.new(object) }

    it 'calls ApplicationDecorator#association_expandable_links with #team_links' do
      team_links = double('Team links')
      expect(decorator).to receive(:team_links).and_return(team_links)

      association_expandable_links = double('Association expandable links')
      expect(decorator).to receive(:association_expandable_links).with(team_links).and_return(association_expandable_links)

      expect(decorator.team_expandable_links).to eq(association_expandable_links)
    end
  end

end
