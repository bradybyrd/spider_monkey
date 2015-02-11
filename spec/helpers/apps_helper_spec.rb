require 'spec_helper'

describe AppsHelper do

  let!(:user){create(:user, :non_root)}

  let(:team1) do
    team1 = mock "Team 1"
    team1.stub(:id).and_return 1
    team1.stub(:name).and_return "Team 1"
    team1
  end

  let(:team2) do
    team1 = mock "Team 2"
    team1.stub(:id).and_return 2
    team1.stub(:name).and_return "Team 2"
    team1
  end

  before(:each) do
    helper.stub(:current_user).and_return(user)
  end

  describe "#options_for_teams" do
    it "returns emty for user without teams" do
      user.stub(:teams).and_return []

      helper.options_for_teams.should eq ""
    end

    it "returns options array of arrays for user with teams" do
      user.stub(:teams).and_return [team1, team2]

      helper.options_for_teams.should eq "<option value=\"1\">Team 1</option>\n<option value=\"2\">Team 2</option>"
    end
  end
end
