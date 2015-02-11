class DraftStateCreateValidator < ActiveModel::Validator

  def validate(record)
    if create_with_nondraft_state?(record)
      record.errors[:aasm_state] << I18n.t(:'object_state.draft_on_create_warning')
    end
  end

  private

  def create_with_nondraft_state?(record)
    record.new_record? && record.aasm_state.present? && record.aasm_state != 'draft' && !record.is_import
  end

end