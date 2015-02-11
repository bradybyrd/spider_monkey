class RequestDashboardView
  attr_reader :request_dashboard

  DEFAULT_REQUEST_PER_PAGE = 20
  REQUEST_PER_PAGE_OPTIONS = [20, 50, 100]
  REQUEST_FILTERED_COLUMNS = %w(aasm_state activity_id app_id package_content_id environment_id
                                release_id team_id requestor_id owner_id assignee_id
                                deployment_window_series_id inbound_outbound)

  def initialize(dashboard_params, filters, session, user)
    @params = dashboard_params
    @filters = filters
    @user = user
    @session = session
    @request_dashboard = {}
  end

  def dashboard_data
    title
    user_app_ids
    user_list_order
    filters
    show_all
    beginning_of_calendar
    end_of_calendar
    request_filtered_columns
    request_filter_block_collapse_state_flag
    request_filters
    per_page
    current_page
    requests
    cache_permissions

    @request_dashboard
  end

  private

  def beginning_of_calendar
    @request_dashboard[:beginning_of_calendar] = @params[:beginning_of_calendar]
  end

  def end_of_calendar
    @request_dashboard[:end_of_calendar] = @params[:end_of_calendar]
  end

  def user_list_order
    @request_dashboard[:user_list_order] = @user.list_order
  end

  def current_page
    @request_dashboard[:page] = @params[:page] || 1
  end

  def request_filtered_columns
    @request_dashboard[:request_filtered_columns] = REQUEST_FILTERED_COLUMNS
  end

  def per_page
    @request_dashboard[:per_page] = requests_per_page
  end

  def request_filter_block_collapse_state_flag
    @request_dashboard[:filter_block_collapse_state_flag] = @params[:filter_block_collapse_state_flag]
  end

  def request_filters
    @request_dashboard[:request_filters] = @params[:filters]
  end

  def filters
    @request_dashboard[:filters] = @params[:filters]
  end

  def show_all
    @request_dashboard[:show_all] = @params[:show_all]
  end

  def requests_data
    @requests = filter_requests
    @requests = search_requests
    @requests = sort_requests
    request_total_count
    @requests = paginate_requests(@requests)
    @requests = preload_request_application_environments(@requests)
    @request_dashboard[:requests] = @requests
  end

  def requests
    @requests = request_relation
    @requests = @requests.promotions if @params[:action] == 'promotions'
    requests_data
  end

  def search_requests
    if @params[:q].present? && @params[:q] != 'Search Requests'
      search_subject, search_key = @params[:q].split(':')

      if search_subject == 'reqid'
        search_request_by_number(search_key)
      elsif search_subject == 'reqname'
        search_request_by_name(search_key)
      else
        @requests.where(name_like(@params[:q]).
                            or(number(@params[:q])).
                            or(aasm_state(@params[:q]))
        )

      end
    else
      @requests
    end
  end

  def name_like(name)
    request_arel[:name].matches("%#{name}%")
  end

  def number(number)
    request_arel[:id].eq("#{number.to_i - GlobalSettings[:base_request_number].to_i}")
  end

  def aasm_state(aasm_state)
    request_arel[:aasm_state].eq(aasm_state)
  end

  def description_like(description)
    request_arel[:description].matches("%#{description}%")
  end

  def wiki_url_like(wiki_url)
    request_arel[:wiki_url].matches("%#{wiki_url}%")
  end

  def request_arel
    Request.arel_table
  end

  def search_request_by_number(request_number)
    @requests.where(number(request_number))
  end

  def search_request_by_name(request_name)
    @requests.where(name_like(request_name))
  end

  def sort_requests
    if @params[:filters][:sort_scope].present?
      @requests.sorted_by(@params[:filters][:sort_scope], @params[:filters][:sort_direction] == 'asc')
    else
      @requests.sorted_by(:id, @user.list_order == 'asc')
    end
  end

  def request_total_count
    @request_dashboard[:requests_total_count] = @requests.size
  end

  def user_app_ids
    @request_dashboard[:current_user_app_ids] = @user.app_ids
  end

  def requests_for_dashboard(request_dashboard)
    return Request if @user.root?
    req = request_dashboard ? Request : Request.participated_in_by(@user)
    req.accessible_to_user(@user)
  end

  def request_relation
    requests_for_dashboard(show_all=='1').extant.exclude_templates.
        includes(:deployment_window_event, :environment, :apps, :activity).
        includes(:release, :owner, plan_member: :plan)
  end

  def title
    @request_dashboard[:title] = 'Requests'
  end

  def preload_request_application_environments(requests)
    RequestApplicationEnvironmentPreloader.new(requests).preload
  end

  def paginate_requests(requests)
    requests.paginate(request_pagination_args)
  end

  def request_pagination_args
    page = @requests.size > requests_per_page ? current_page : 1
    pagination_args = {page: page, per_page: requests_per_page}

    if @filters[:sort_scope].blank?
      pagination_args = pagination_args.merge(order: "requests.id #{@user.list_order}")
    end

    pagination_args
  end

  def requests_per_page
    @params[:filters][:per_page].blank? ? DEFAULT_REQUEST_PER_PAGE : @params[:filters][:per_page].to_i
  end

  def cache_permissions
    @request_dashboard[:can_create_request]               = @user.can?(:create, Request.new)
    @request_dashboard[:can_import_request]               = @user.can?(:import, Request.new)
    @request_dashboard[:can_view_requests_list]           = @user.can?(:view_requests_list, Request.new)
    @request_dashboard[:can_view_calendar]                = @user.can?(:view_calendar, Request.new)
    @request_dashboard[:can_view_currently_running_steps] = @user.can?(:view_currently_running_steps, Request.new)
  end

  def filter_requests
    @session[session_filter_var] ||= HashWithIndifferentAccess.new

    if @params[:filters].present?
      sanitized_params = @params[:filters]
      sanitized_params.each { |k, v| sanitized_params[k] = ERB::Util.html_escape(v) if v.is_a?(String) }
      @session[session_filter_var].replace(sanitized_params)
    end

    @request_filters = @session[session_filter_var]

    if @request_filters[:aasm_state].present? && !@request_filters[:aasm_state].include?('deleted')
      @requests = @requests.functional
    end

    if @user.cannot?(:view_created_requests_list, Request.new) &&
        @params[:request_ids].blank? # Skipped when user is viewing Recently Updated Requests page
      @requests = @requests.in_progress
    end

    if @request_filters.present?
      @requests = @requests.filtered(@request_filters, @user)
    end

    if @params[:beginning_of_calendar].present? || @params[:end_of_calendar].present?
      @requests = @requests.between_dates(@params[:beginning_of_calendar], @params[:end_of_calendar])
    end

    @request_dashboard[:request_filters] = @request_filters

    @requests
  end

  def session_filter_var
    "#{@params[:controller]}_#{@params[:action]}"
  end
end
