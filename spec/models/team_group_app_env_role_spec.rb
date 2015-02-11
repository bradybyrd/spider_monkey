require 'spec_helper'

describe TeamGroupAppEnvRole do
  let(:attributes)  {{
    application_environment_id: 1,
    team_group_id:              2,
    role_id:                    3
  }}

  describe 'validators' do
    it { expect(subject).to validate_presence_of :team_group_id }
    it { expect(subject).to validate_presence_of :application_environment_id }
  end

  describe '#set' do
    it 'creates a new instance' do
      expect{TeamGroupAppEnvRole.set(attributes)}.to change{TeamGroupAppEnvRole.count}.by(1)
    end

    it 'will not create a new instance if one exists' do
      TeamGroupAppEnvRole.set(attributes)
      expect{TeamGroupAppEnvRole.set(attributes)}.to_not change{TeamGroupAppEnvRole.count}.by(1)
    end

    it 'updates the existing entry' do
      TeamGroupAppEnvRole.set(attributes)
      attributes[:role_id]  = 4
      TeamGroupAppEnvRole.set(attributes)
      expect(TeamGroupAppEnvRole.last.role_id).to eq 4
    end

    it 'returns a TeamGroupAppEnvRole when creating' do
      result = TeamGroupAppEnvRole.set(attributes)
      expect(result).to be_a TeamGroupAppEnvRole
    end

    it 'returns a TeamGroupAppEnvRole when updating' do
      TeamGroupAppEnvRole.set(attributes)
      result = TeamGroupAppEnvRole.set(attributes)
      expect(result).to be_a TeamGroupAppEnvRole
    end

    context 'when role_id not given' do
      let(:attributes)  {{
          application_environment_id: 1,
          team_group_id:              2
      }}

      before { TeamGroupAppEnvRole.create(attributes.merge(role_id: 3)) }

      it 'deletes the entry' do
        expect{TeamGroupAppEnvRole.set(attributes)}.to change{TeamGroupAppEnvRole.count}.from(1).to(0)
      end
    end
  end

end
