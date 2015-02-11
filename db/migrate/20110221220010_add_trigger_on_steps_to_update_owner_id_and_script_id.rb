################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


# This migration is not set to be executed as there are some permission issues
# in database used at client side so return statement is added before the method body
# so nothing is executed and Step#set_owner_attributes is added to do the same

class AddTriggerOnStepsToUpdateOwnerIdAndScriptId < ActiveRecord::Migration

  def self.up
    return
    # update_step_owner_on_create => usoc
    execute(
      "CREATE TRIGGER  trigger_usoc " + 
      "BEFORE INSERT ON steps " +
      "FOR EACH ROW " +
      "BEGIN " +
      "IF NEW.manual = 1 THEN " +
      "SET NEW.script_id = NULL; " + 
      "SET NEW.script_type = NULL; " +
      "ELSEIF NEW.manual = 0 THEN " +
      "SET NEW.owner_id = NULL; " + 
      "SET NEW.owner_type = NULL; " +
      "END IF; " + 
      "END")
      
    execute(
      "CREATE TRIGGER trigger_usou " + 
      "BEFORE UPDATE ON steps " +
      "FOR EACH ROW " +
      "BEGIN " +
      "IF NEW.manual = 1 THEN " +
      "SET NEW.script_id = NULL; " + 
      "SET NEW.script_type = NULL; " +
      "ELSEIF NEW.manual = 0 THEN " +
      "SET NEW.owner_id = NULL; " + 
      "SET NEW.owner_type = NULL; " +
      "END IF; " + 
      "END")
end
  def self.down
    return
    execute("DROP TRIGGER trigger_usoc")
    execute("DROP TRIGGER trigger_usou")
  end
end

# execute("CREATE TRIGGER update_pa_aasm_state BEFORE UPDATE ON passport_applications " +
# "FOR EACH ROW " +
# "BEGIN " +
# "IF OLD.aasm_state = 'received' AND OLD.sent_for_verification_at IS NULL AND NEW.sent_for_verification_at IS NOT NULL THEN " +
# "SET NEW.aasm_state = 'in_process'; " +
# "ELSEIF OLD.aasm_state = 'in_process' AND OLD.sent_for_verification_at IS NOT NULL AND OLD.received_after_verification_at IS NULL AND NEW.received_after_verification_at IS NOT NULL THEN " +
# "SET NEW.aasm_state = 'complete'; " +
# "ELSEIF OLD.aasm_state = 'complete' AND OLD.received_after_verification_at IS NOT NULL AND OLD.sent_to_po_at IS NULL AND NEW.sent_to_po_at IS NOT NULL THEN " +
# "SET NEW.aasm_state = 'delivered_to_po'; " +
# "END IF; " +
# "END")
