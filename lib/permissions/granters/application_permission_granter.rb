require 'accessible_app_environment_query'
require 'user_permissions_query'

class ApplicationPermissionGranter < PermissionGranter
  set_key :app_id

  value_for(App)              { |app| app.id }
  value_for(Request)          { |request| request.apps.map(&:id) }
  value_for(Component)        { |component| component.app_ids }
  value_for(Environment)      { |environment| environment.apps.map(&:id) }
  value_for(BusinessProcess)  { |business_process| business_process.apps.pluck(:id) }
  value_for(PackageInstance)  { |package_instance| package_instance.apps.map(&:id) }
  value_for(RequestTemplate)  { |request_template|
    request_template.request.present? ? request_template.request.apps.map(&:id) : []
  }

  def grant?(action, obj)
    subject = PermissionGranter.get_subject(obj)

    if (values = get_values_for(obj)).empty?
      PermissionMap.instance.has_user_global_access?(@user, subject, action)
    else
      PermissionMap.instance.has_any_app_access_for_apps?(@user, subject, action, values)
    end
  end
end
