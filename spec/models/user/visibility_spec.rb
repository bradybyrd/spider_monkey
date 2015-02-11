require 'spec_helper'

describe User do
  describe '#accessible_default_environments' do
    context 'root user' do
      let!(:user) { create(:user, :root) }

      it 'returns active environments' do
        active_envs = create_list(:environment, 3)
        inactive_env = create(:environment, active: false)

        expect(user.accessible_default_environments).to match_array(active_envs)
      end
    end
  end

  describe '#get_disabled_environments' do
    context 'root user' do
      let(:active_envs) { create_list(:environment, 3) }
      let(:app) { create(:app) }
      let!(:user) { create(:user, :root) }

      it 'returns blank array' do
        user.stub(:cannot?).and_return(false)
        expect(user.get_disabled_environments(app, active_envs)).to match_array([])
      end

      it 'returns environments to be disabled' do
        user.stub(:cannot?).and_return(true)
        expect(user.get_disabled_environments(app, active_envs)).to match_array(active_envs)
      end
    end
  end
end
