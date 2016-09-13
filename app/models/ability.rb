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
    elsif SystemSetting.requests_enabled?
      cannot :manage, Status
      can :manage, PlaceholderResource
      if user.deployer? or user.deployment_coordinator?
        cannot :manage, SystemSetting
        cannot :manage, User
        cannot :manage, Group
        cannot :manage, Team
        can    :manage, Environment
        can    :manage, MetaData
        can    :manage, Property 
        can    :manage, Request
        can    :manage, Lifecycle
        can    :manage, LifecycleTemplate
        can    :manage, Activity
        can    :manage, App
        can    :manage, Server
        can    :manage, List
        can    :manage, Property
        can    :manage, Procedure
        can    :manage, BusinessProcess
        can    :manage, RequestTemplate
        can    :manage, Category
        can    :manage, Task
        can    :manage, Release
        can    :manage, Task
        if user.deployer?
          can  :manage, AutomationScript
        end 
      elsif user.requestor?
        can    :read,   RequestTemplate
        cannot :manage, RequestTemplate
        can    :manage, Request
        cannot :manage, Property
        cannot :manage, Lifecycle
        cannot :manage, Activity
        cannot :manage, Procedure # Considered same for Procedure Steps also
      elsif user.user?
        can    :update, Step 
        cannot :manage, App 
        cannot :manage, Property
        cannot :manage, Lifecycle
        cannot :manage, Activity
        cannot :manage, Procedure
      end
    end
  end
  
end



class MetaData; end