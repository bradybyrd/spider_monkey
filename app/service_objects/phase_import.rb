class PhaseImport

  attr_reader :step, :params

  def initialize(step, params = {})
    @step = step
    @params = params
  end

  def import!
    if params.has_key?('phase')
      phase = build_phase_from!(params['phase'])
      RuntimePhaseImport.new(phase, step, params).import!
    end
  end

  private

  def build_phase_from!(phase_params)
    phase = Phase.where(name: phase_params['name']).first_or_initialize
    phase.archive_number = phase_params['archive_number']
    phase.archived_at = phase_params['archived_at']
    phase.insertion_point = phase_params['position']
    phase.save!

    step.phase_id = phase.id
    phase
  end
end
