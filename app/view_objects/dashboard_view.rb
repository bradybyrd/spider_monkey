class DashboardView
  def initialize(dashboard_params, filters, user)
    @params = dashboard_params
    @filters = filters
    @user = user
    @request_dashboard = {}
  end

  def dashboard_data
    title
    current_users
    dashboard_permissions
    calendar
    total_inbound_requests
    total_outbound_requests

    @request_dashboard
  end

  private

  def calendar
    @request_dashboard[:beginning_of_calendar] = @params[:beginning_of_calendar]
    @request_dashboard[:end_of_calendar] = @params[:end_of_calendar]
  end

  def title
    @request_dashboard[:title] = 'My Dashboard'
  end

  def current_users
    # Limit the user count for performance reasons
    @request_dashboard[:current_users] = User.select_id_name_email_login.active.
        currently_logged_in(@user.id).index_order.limit(100)
  end

  def total_inbound_requests
    @request_dashboard[:total_inbound_request] = Request.inbound(@user).count
  end

  def total_outbound_requests
    @request_dashboard[:total_outbound_request] = Request.outbound(@user).count
  end


  def dashboard_permissions
    @request_dashboard[:can_create_requests]          = @user.can?(:create, Request.new)
    @request_dashboard[:view_calendar]                = @user.can?(:view, :dashboard_calendar)
    @request_dashboard[:view_promotions]              = @user.can?(:view, :dashboard_promotions)
    @request_dashboard[:view_my_applications]         = @user.can?(:view, :my_applications)
    @request_dashboard[:view_my_environments]         = @user.can?(:view, :my_environments)
    @request_dashboard[:view_my_servers]              = @user.can?(:view, :my_servers)
    @request_dashboard[:view_my_requests]             = @user.can?(:view, :my_requests)
    @request_dashboard[:view_currently_running_steps] = @user.can?(:view, :running_steps)
  end
end