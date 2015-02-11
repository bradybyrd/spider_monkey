require 'spec_helper'

describe ProcedureImport do
  describe '#call' do
    context 'procedure does not exist' do
      it 'creates procedure' do
        procedures_data = [ { 'name' => 'Procedure 1', 'aasm_state' => 'released' } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        expect { importer.call }.to change { Procedure.count }.by 1
        expect(Procedure.where(name: 'Procedure 1').first).to be_present
      end

      it 'links procedure with app' do
        procedures_data = [ { 'name' => 'Procedure 1' } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        importer.call

        expect(Procedure.where(name: 'Procedure 1').first.apps).to include app
      end

      it 'creates steps' do
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 1' },
                                           { 'name' => 'Step 2' } ] } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        expect { importer.call }.to change { Step.count }.by 2
        expect(Step.where(name: 'Step 1').first).to be_present
        expect(Step.where(name: 'Step 2').first).to be_present
      end

      it 'creates steps with components' do
        component = create :component, name: 'comp1'
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 1', 'component' => {'name' => 'comp1'} },
                                           { 'name' => 'Step 2' } ] } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        expect { importer.call }.to change { Step.count }.by 2
        expect(Step.where(name: 'Step 1').first.component_id).to eql(component.id)
      end
    end

    context 'procedure without steps exists' do
      describe 'update procedure' do
        it 'updates state' do
          procedure = create :procedure, name: 'Procedure 1',
                                         aasm_state: 'pending'
          procedures_data = [ { 'name' => 'Procedure 1', 'aasm_state' => 'archived_state' } ]
          app = create :app
          importer = ProcedureImport.new(procedures_data, app)

          expect { importer.call }.to change { procedure.reload.aasm_state }
            .from('pending')
            .to('archived_state')
        end

        it 'updates description' do
          procedure = create :procedure, name: 'Procedure 1',
                                         description: 'Some description blah-blah-blah.'
          procedures_data = [ { 'name' => 'Procedure 1', 'description' => 'Altered description.' } ]
          app = create :app
          importer = ProcedureImport.new(procedures_data, app)

          expect { importer.call }.to change { procedure.reload.description }
            .from('Some description blah-blah-blah.')
            .to('Altered description.')
        end
      end

      it 'creates steps' do
        procedure = create :procedure, name: 'Procedure 1'
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 1' },
                                           { 'name' => 'Step 2' } ] } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        expect { importer.call }.to change { Step.count }.by 2
        expect(Step.where(name: 'Step 1').first).to be_present
        expect(Step.where(name: 'Step 2').first).to be_present
      end
    end

    context 'procedure with steps exists' do
      it 'overwrites steps' do
        procedure = create :procedure, :with_steps, name: 'Procedure 1'
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 11' },
                                           { 'name' => 'Step 22' } ] } ]
        app = create :app
        importer = ProcedureImport.new(procedures_data, app)

        expect { importer.call }.not_to change { Step.count }
        expect(Step.where(name: 'Step 11').first).to be_present
        expect(Step.where(name: 'Step 22').first).to be_present
      end
    end

    context 'procedure with a step which contains an automation script' do
      it 'contains a non-existing automation script' do
        script_attributes = create_automation_step_attributes name: 'AutoScript', automation_category: 'SuperScripts'

        procedure = create :procedure, :with_steps, name: 'Procedure 1'
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 11' }.merge(script_attributes) ] } ]

        ProcedureImport.new(procedures_data, create(:app)).call

        step = Step.first

        expect(step.script_type).to eq('Manual')
        expect(step.script_id).to be_nil
      end

      it 'contains an existing automation script' do
        script = create :script, name: 'AutoScript', automation_category: 'SuperScripts'
        script_attributes = create_automation_step_attributes name: 'AutoScript', automation_category: 'SuperScripts'

        procedure = create :procedure, :with_steps, name: 'Procedure 1'
        procedures_data = [ { 'name' => 'Procedure 1',
                              'steps' => [ { 'name' => 'Step 11' }.merge(script_attributes) ] } ]

        ProcedureImport.new(procedures_data, create(:app)).call

        step = Step.first

        expect(step.script_type).not_to eq('Manual')
        expect(step.script_id).to eq(script.id)
      end
    end
  end

  def create_automation_step_attributes(args={})
    create_automation_category(args[:automation_category])
    automation_step_attributes(args)
  end

  def create_automation_category(automation_category_name)
    list = create :list, name: 'AutomationCategory'
    create :list_item, value_text: automation_category_name, list: list
  end

  def automation_step_attributes(options = {})
    automation_category = options.fetch(:automation_category, 'category')
    automation_type = options.fetch(:automation_type, 'General')
    automation_content = options.fetch(:content, 'print "Hello World"')
    automation_name = options.fetch(:name, 'name')
    script_type = options.fetch(:script_type, 'General')
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
