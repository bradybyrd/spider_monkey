class StepDecorator < ApplicationDecorator
  decorates :step

  delegate_all

  def component_name_formatted
    h.ensure_space(component_name).html_safe
  end

  private

  def component_name
    if step.package_template.present? && step.component_id.nil?
      step.package_template.name
    elsif step.package.present?
      step.package.name
    else
      step.component_name
    end
  end

end
