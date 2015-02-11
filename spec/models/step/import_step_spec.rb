require 'spec_helper'

describe Step do
  describe '#build_step' do
    it 'creates a step that belongs to the procedure' do
      app = double :app, id: 1
      user = create :user, :non_root
      request = create :request
      procedure = create :step, name: 'procedure_template_1', procedure: true, request_id: request.id

      step = Step.build_step(request, procedure_step_attributes(procedure.name), app, user)

      expect(procedure.steps.reload).to include step
    end

    context 'for a step with automation script' do
      it 'creates a step without automation script if AutomationCategory does not exists' do
        app = double :app, id: 1
        user = create :user, :non_root
        request = create :request

        step = Step.build_step(request, automation_step_attributes(automation_category: 'non existing'), app, user)

        expect(step.script).to be_nil
      end

      it 'creates a step without automation script if no script attributes in import' do
        app = double :app, id: 1
        user = create :user, :non_root
        request = create :request

        step = Step.build_step(request, step_default_attributes, app, user)

        expect(step.script).to be_nil
      end

      it 'creates a step and uses automation task script if automation task exists' do
        app = double :app, id: 1
        user = create :user, :non_root
        request = create :request
        script = create :script, name: 'Pwned them all', automation_category: 'Automation'
        script_attributes = create_automation_step_attributes name: script.name, automation_category: 'SuperScripts'

        step = Step.build_step(request, script_attributes, app, user)

        expect(step.script_id).to eq script.id
        expect(step.script).to be_an_instance_of Script
      end

      it 'creates a step and uses existing bladelogic automation script if AutomationTask exists' do
        app = double :app, id: 1
        user = create :user, :non_root
        request = create :request
        script = create :bladelogic_script, name: 'Pwned them all'
        script_attributes = create_automation_step_attributes name: script.name,
                                                              automation_category: 'BMC Application Automation 8.2',
                                                              script_type: 'BladelogicScript'
        enable_automations

        step = Step.build_step(request, script_attributes, app, user)

        expect(step.script_id).to eq script.id
        expect(step.script).to be_an_instance_of BladelogicScript
      end

      def create_automation_step_attributes(args={})
        create_automation_category(args[:automation_category])
        automation_step_attributes(args)
      end

      def create_automation_category(automation_category_name)
        list = create :list, name: 'AutomationCategory'
        create :list_item, value_text: automation_category_name, list: list
      end
    end

  end

  def procedure_step_attributes(procedure_name)
    HashWithIndifferentAccess.new(
        step_default_attributes.merge(
            {
                'parent' => {'type' => 'Step',
                             'name' => procedure_name}
            })
    )
  end

  def step_script_argument_attributes
    {'step_script_arguments' =>
         [
             {'script_argument_type' => 'ScriptArgument',
              'value' => [['ls']],
              'script_argument' => {'argument' => 'command',
                                    'name' => 'Name of command',
                                    'script' => {'name' => 'Direct_execute', 'template_script_type' => nil}
              }
             }
         ]
    }
  end

  def automation_step_attributes(options = {})
    automation_category = options.fetch(:automation_category, 'category')
    automation_type = options.fetch(:automation_type, 'type')
    automation_content = options.fetch(:content, 'print "Hello World"')
    automation_name = options.fetch(:name, 'name')
    script_type = options.fetch(:script_type, 'script_type')
    step_default_attributes.
        merge('script_type' => script_type).
        merge({'script' =>
                   {'automation_category' => automation_category,
                    'automation_type' => automation_type,
                    'content' => automation_content,
                    'name' => automation_name,
                    'description' => 'cool script description'
                   }
              }).
        merge(step_script_argument_attributes)
  end


  def step_default_attributes
    {
        'aasm_state' => 'locked',
        'complete_by' => nil,
        'component_version' => nil,
        'default_tab' => 'properties',
        'description' => nil,
        'different_level_from_previous' => true,
        'estimate' => 5,
        'execute_anytime' => false,
        'name' => 'p_step_1',
        'own_version' => false,
        'owner_type' => 'User',
        'procedure' => false,
        'protected_step' => false,
        'should_execute' => true,
        'start_by' => nil,
        'suppress_notification' => false,
        'component' => {'name' => 'SS_RailsApp'},
        'owner' => {'type' => 'User', 'name' => 'Administrator, John'},
        'notes' => [], 'parent' => {'type' => 'Step', 'name' => 'procedure_template_1'},
        'temporary_property_values' => [],
        'step_script_arguments' => []
    }
  end
end
