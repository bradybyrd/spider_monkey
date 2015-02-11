module RunsHelper

  def show_alert_for_scheduling(request)
    run_start_date = request.run.try(:start_at)
    request_scheduled_at = request.scheduled_at
    if run_start_date.present? && request_scheduled_at.present?
      run_start_date > request_scheduled_at ? "#FFBBBB" : ""
    end
  end

  def disable_date_field_for_run?(run)
    (run.aasm_state == 'created' || run.aasm_state == 'planned') ? false : true
  end

  def disable_date_field_for_request?(request, new_run)
     return false if new_run
    (request.aasm_state == 'created' || request.aasm_state == 'planned') ? false : true
  end

  def available_environments_for_request_menu(plan_stage_instance, request)

    # get the app and the environments as a fall back
    app = request.apps.first
    all_environments = app.try(:environments) || []
    plan = plan_stage_instance.try(:plan)

    # if the request has a plan stage, check for constraints
    if request.present? && request.has_plan_stage? && plan.try(:is_constrained?)
      environments_for_menu = plan_stage_instance.allowable_environments_for_request(request)
    elsif all_environments.present?
      environments_for_menu = all_environments.order('environments.name ASC')
    end
    available_environments_select(environments_for_menu, request)
  end

  def available_environments_select(environments_for_menu, request)
    request_environment = [[request.environment_name, request.environment_id]]
    menufied_environments = environments_for_menu.map { |e| [e.name, e.id] }.presence || request_environment
    select_tag "run[requests_planned_date[#{request.id}][environment_id]",
               options_for_select(menufied_environments,
                                  :selected => request.try(:environment_id)),
               :class => 'request_environment_id',
               :disabled => environments_for_menu.blank? || environments_for_menu.include?('None')

  end

  def request_auto_start_errors_of(run)
    content_tag :div, id: 'request_auto_start_errors', class: 'errorExplanation' do
      content_tag :ul do
        run.requests.with_auto_start_errors.map do |request|
          content_tag(:li, "Request #{request.number}: #{request.automatically_start_errors}" )
        end.join('').html_safe
      end
    end
  end

end
