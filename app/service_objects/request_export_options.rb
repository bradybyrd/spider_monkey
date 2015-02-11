class RequestExportOptions

  attr_reader :options

  def initialize(include_automations = false)
    @include_automations = include_automations
    @options = request_options
  end

  private

  def request_options
    if export_automations?
      request_hash_with_automations
    else
      requests_hash
    end
  end

  def request_hash_with_automations
    hash_with_automations = requests_hash
    hash_with_automations[:include][:request_template][:methods] = :automation_scripts_for_export
    hash_with_automations
  end

  def requests_hash
    {
      only: [:name, :description, :wiki_url, :aasm_state, :rescheduled, :estimate,
             :auto_start, :target_completion_at, :scheduled_at, :notify_on_step_start,
             :notify_on_request_start, :notify_on_request_hold, :notify_on_request_complete,
             :notify_on_step_block, :notify_on_step_complete, :additional_email_addresses,
             :notify_on_request_cancel, :notify_on_step_problem, :notify_on_step_ready,
             :notify_on_request_planned, :notify_on_request_problem, :notify_on_request_resolved,
             :notify_on_request_step_owners, :notify_on_step_step_owners, :notify_on_step_requestor_owner,
             :notify_on_request_participiant, :notify_on_step_participiant, :notify_group_only],

      include: {
        request_template: { only: [:name, :aasm_state] },
        environment: { only: [:name] },
        notes: { only: [:content],methods: [:user_name] },
        business_process: { only: [:name] },
        release: { only: [:name] },
        owner: { only: [:name],  methods: [:name] },
        requestor: { only: [:name], methods: [:name] },
        email_recipients: {only: [:recipient_type],methods: [:recipient_name]},
        package_contents: { only: [:name] },
        steps: steps_hash
        }
    }
  end

  def export_automations?
    @include_automations
  end

  def steps_hash
    StepExportOptions.new(export_automations?).options
  end

end