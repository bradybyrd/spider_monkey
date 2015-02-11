class ScriptAssociaterFactory
  BLADELOGIC_SCRIPT_TYPE = 'BladelogicScript'
  AUTOMATION_CATEGORY_NAME = 'AutomationCategory'

  attr_reader :step, :script_attributes

  def initialize(step, script_attributes)
    @step = step
    @script_attributes = script_attributes
  end

  def instance
    importer_by_script_type
  end

  private

  def importer_by_script_type
    script = find_script

    if automation_category.blank? || script.blank?
      StepService::ScriptImporter::NullScriptAssociater.new(step)
    elsif bladelogic?
      StepService::ScriptImporter::BladelogicScriptAssociater.new(step, script, script_attributes)
    else
      StepService::ScriptImporter::AutomationScriptAssociater.new(step, script, script_attributes)
    end
  end

  def automation_category
    if script_attributes[:automation_category].present?
      if bladelogic?
        GlobalSettings[:bladelogic_enabled]
      else
        automation_category_list.list_items.where(value_text: script_attributes[:automation_category])
      end
    end
  end

  def automation_category_list
    List.find_by_name(AUTOMATION_CATEGORY_NAME) || empty_automation_category_list
  end

  def empty_automation_category_list
    List.new
  end

  def find_script
    if script_attributes[:name].present?
      if bladelogic?
        BladelogicScript.find_by_name(script_attributes[:name])
      else
        Script.find_by_name(script_attributes[:name])
      end
    end
  end

  def bladelogic?
    script_attributes[:type] == BLADELOGIC_SCRIPT_TYPE
  end
end
