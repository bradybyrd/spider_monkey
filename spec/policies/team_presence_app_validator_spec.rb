require 'spec_helper'

describe TeamPresenceAppValidator, custom_roles: true do
  describe "#valid?" do
    it 'is valid if app contains teams' do
      team = create(:team)
      validator = TeamPresenceAppValidator.new(build(:app, team_ids: [team.id]))

      expect(validator).to be_valid
    end

    it 'is not valid if app is w/o teams' do
      app = build(:app)
      TeamPresenceAppValidator.new(app).valid?

      expect(app.errors.messages[:team_ids]).to include "can't be blank"
    end
  end
end
