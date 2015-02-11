require 'context_root'

class MainTabs
  PERMISSIONS_PATHS = ActiveSupport::OrderedHash.new
  PERMISSIONS_PATHS[:dashboard_tab] = ContextRoot.context_root + '/'
  PERMISSIONS_PATHS[:plans_tab] = ContextRoot.context_root + '/plans'
  PERMISSIONS_PATHS[:requests_tab] = ContextRoot.context_root + '/request_dashboard'
  PERMISSIONS_PATHS[:volume_report] = ContextRoot.context_root + '/reports/process?report_type=volume_report'
  PERMISSIONS_PATHS[:reports_tab] = ContextRoot.context_root + '/reports'
  PERMISSIONS_PATHS[:applications_tab] = ContextRoot.context_root + '/apps'
  PERMISSIONS_PATHS[:environment_tab] = ContextRoot.context_root + '/environment/servers'
  PERMISSIONS_PATHS[:system_tab] = ContextRoot.context_root + '/users'

  DEFAULT_RESCUE_PATH = ContextRoot.context_root + '/dashboard'
  DEFAULT_ROOT_PATH = ContextRoot.context_root + '/'

  def self.root_path(user = nil)
    if user.present?
      PERMISSIONS_PATHS.reduce(nil) { |_, (subj, path)| user.can?(:view, subj) ? (break path) : DEFAULT_RESCUE_PATH }
    else
      DEFAULT_ROOT_PATH
    end
  end

  def self.selected_any?(user = nil)
    PERMISSIONS_PATHS.keys.map { |subj| user.can?(:view, subj) }.inject(:|) if user.present?
  end
end
