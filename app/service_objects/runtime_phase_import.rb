class RuntimePhaseImport

  attr_reader :phase, :step, :params

  def initialize(phase, step, params = {})
    @phase = phase
    @step = step
    @params = params
  end

  def import!
    if params.has_key?('runtime_phase')
      build_runtime_phase_from!(params['runtime_phase'])
    end
  end

  private

  def build_runtime_phase_from!(runtime_params)
    runtime_phase = phase.runtime_phases.where(name: runtime_params['name']).first_or_initialize
    runtime_phase.insertion_point = runtime_params['position']
    runtime_phase.save!

    step.runtime_phase_id = runtime_phase.id
    runtime_phase
  end
end
