class TeamGroupAppEnvRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :team_group
  belongs_to :application_environment
  has_one :team,        through: :team_group
  has_one :group,       through: :team_group
  has_one :app,         through: :application_environment
  has_one :environment, through: :application_environment

  attr_accessible :role_id, :team_group_id, :application_environment_id
  validates_presence_of :team_group_id, :application_environment_id

  delegate :team, :group, to: :team_group
  delegate :app, :environment, to: :application_environment

  acts_as_audited protect: true

  def self.set(attributes)
    great = self.exists(attributes).first
    self.create_or_update(great, attributes).tap do |instance|
      #instance.role && PermissionMap.instance.bulk_clean(instance.role.users)
    end
  end

  def self.exists(attributes)
    self.where(team_group_id: attributes[:team_group_id], application_environment_id: attributes[:application_environment_id])
  end

  def self.create_or_update(great, attributes)
    if attributes[:role_id].present? && great.present?
      great.update_attribute(:role_id, attributes[:role_id]) && great
    elsif great.present?
      great.destroy
    else
      self.create(attributes)
    end
  end

  def team_id
    team.id
  end

  def group_id
    group.id
  end

  def app_id
    app.id
  end

  def environment_id
    environment.id
  end

end
