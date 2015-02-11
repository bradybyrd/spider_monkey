module DeploymentWindowsHelper
  def link_to_active_requests(deployment_window_series, requests, environment_id = nil)
    active_requests_link_name = "#{requests.count} #{t('request.active')}"
    filters = {
        'filters[deployment_window_series_id][]' => deployment_window_series.id,
        'filters[aasm_state][]' => 'active'
    }
    filters = filters.merge({'filters[environment_id][]' => environment_id}) if environment_id

    link_to active_requests_link_name, request_dashboard_path(filters), target: '_blank'
  end
end
