module StepHelper
  def create_step_with_invalid_package
    step = create_step_with_valid_package
    remove_app_associations_from_package(step.package)
    step
  end

  def create_step_with_valid_package
    package = create(:package)
    app = create(:app, packages: [package])
    request = create(:request)
    create(:apps_request, app: app, request: request)
    step = create(
      :step,
      related_object_type: 'package',
      request: request,
      package: package
    )
  end

  def create_procedure_step_with_invalid_package
    step = create_procedure_step_with_valid_package
    remove_app_associations_from_package(step.package)
    step
  end

  def create_procedure_step_with_valid_package
    package = create(:package)
    app = create(:app, packages: [package])
    procedure = create(:procedure, apps:[app])
    step = create(
        :step,
        related_object_type: 'package',
        floating_procedure: procedure,
        package: package,
        request: nil
    )
  end

  def remove_app_associations_from_package(package)
    ApplicationPackage.where(package_id: package).destroy_all
  end
end
