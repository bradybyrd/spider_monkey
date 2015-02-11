require 'spec_helper'

describe TeamDecorator do

  describe '#link' do
    let(:team){ mock_model Team }
    subject(:decorator){ TeamDecorator.new(team) }

    it 'returns edit link to object with object name' do
      url = double('URL')
      expect(h).to receive(:edit_team_path).with(team).and_return(url)
      link = double('Link')
      expect(h).to receive(:link_to).with(team.name, url).and_return(link)

      expect(decorator.link).to eq(link)
    end
  end

  describe '#app_checkbox_hint' do
    it 'returns app hint when it is disabled' do
      team = build(:team)
      decorator = TeamDecorator.new(team)
      app = mock('app')
      team_policy = mock('team_policy')
      allow(decorator).to receive(:object_policy).and_return(team_policy)
      allow(team_policy).to receive(:app_disabled?).and_return(true)

      expect(decorator.app_checkbox_hint(app)).to eq(I18n.t('team.app_checkbox_disabled_hint'))
    end
  end

  describe '#group_checkbox_hint' do
    it 'returns group hint when it is disabled' do
      team = build(:team)
      decorator = TeamDecorator.new(team)
      group = mock('app')
      team_policy = mock('team_policy')
      allow(decorator).to receive(:object_policy).and_return(team_policy)
      allow(team_policy).to receive(:group_disabled?).and_return(true)

      expect(decorator.group_checkbox_hint(group)).to eq(I18n.t('team.group_checkbox_disabled_hint'))
    end
  end

end
