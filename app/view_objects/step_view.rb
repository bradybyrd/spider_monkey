class StepView
  attr_reader :step

  def initialize(step)
    @step = step
  end

  def script_name
    step.script.try(:name) || I18n.t('step.script_deleted')
  end

end