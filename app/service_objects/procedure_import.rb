class ProcedureImport
  attr_reader :procedures, :app
  private :procedures, :app

  AFFECTED_PROCEDURE_FIELDS = %w(name description aasm_state)
  AFFECTED_STEP_FIELDS = %w(name aasm_state component_version
                            description start_by complete_by
                            suppress_notification default_tab
                            execute_anytime different_level_from_previous
                            start_by complete_by own_version estimate
                            protected_step should_execute procedure
                            owner_type script_type)

  def initialize(procedures, app)
    @procedures = procedures || []
    @app = app
  end

  def call
    procedures.each do |procedure_params|
      procedure = build_procedure_from_params(procedure_params)
      procedure.save
    end
  end

  private

  def build_procedure_from_params(procedure_params)
    procedure = Procedure.where(name: procedure_params['name']).first_or_create
    AFFECTED_PROCEDURE_FIELDS.each { |field| procedure.send :"#{field}=", procedure_params[field] if procedure_params[field].present? }
    procedure.steps = build_steps_from_params(procedure_params['steps'])
    procedure.apps << app
    procedure
  end

  def build_steps_from_params(steps_params)
    if steps_params.present?
      steps_params.map { |params| build_step_from_params params }
    else
      []
    end
  end

  def build_step_from_params(step_params)
    step = Step.new
    AFFECTED_STEP_FIELDS.each { |field| step.send :"#{field}=", step_params[field] if step_params[field].present? }
    step.component_id = component_id(step_params['component'] || {})
    step.owner = step_owner step_params['owner']
    set_script(step, step_params['script'])
    step
  end

  def set_script(step, script_params)
    if script_params.present?
      script = Script.find_script(script_params['name'])
      if script.nil?
        step.script_type = 'Manual'
      else
        step.script = script;
      end
    end
  end

  def step_owner(owner_params)
    owner = OwnerFactory.build owner_params
    owner.record || User.current_user
  end

  def component_id(component_params)
    if component_params.has_key? 'name'
      component = Component.find_by_name(component_params['name'])
      component.id if component.present?
    end
  end

  class OwnerFactory
    def self.build(owner_params)
      case owner_params['type']
      when 'User'
        UserOwner.new owner_params['name']
      when 'Group'
        GroupOwner.new owner_params['name']
      else
        NilOwner.new
      end
    end
  end

  class UserOwner
    attr_reader :first_name, :last_name
    private :first_name, :last_name

    def initialize(name)
      @last_name, @first_name = name.split(', ')
    end

    def record
      User.where(first_name: first_name, last_name: last_name).first
    end
  end

  class GroupOwner
    attr_reader :name
    private :name

    def initialize(name)
      @name = name
    end

    def record
      Group.where(name: name).first
    end
  end

  class NilOwner
    def record
      nil
    end
  end
end
