class TeamPresenceAppValidator
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def valid?
    app.valid?
    check_team_assignment
    app.errors.blank?
  end

  private

  def check_team_assignment
    app.errors.add(:team_ids, :blank) if app.team_ids.blank?
  end
end
