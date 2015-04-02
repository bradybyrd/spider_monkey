class Ability
  
  include CanCan::Ability
  
  def initialize(user)
    if user.admin? or user.has_global_access?
      can :manage, :all
    elsif SystemSetting.portfolio_enabled?
      cannot :manage, Status
      if user.resource_manager?
        can :manage, PlaceholderResource
      else
        cannot :manage, PlaceholderResource
      end
      if user.is_fm? or user.is_pm?
        can :manage, BudgetLineItem
      else
        cannot :manage, BudgetLineItem
      end
  end
  
end


class MetaData; end