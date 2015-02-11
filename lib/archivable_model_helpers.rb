################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
###
#
# Any class including this module may need to  provide for an implementation of these two instance methods
# 1> destroyable? 2> can_be_archived?
#
###
module ArchivableModelHelpers

  MAX_ITEMS_IN_IN_STATEMENT = 999

  attr_accessor :just_unarchived

  def self.included(base)
    # gem handling activate and deactivate methods: https://github.com/expectedbehavior/acts_as_archival
    base.acts_as_archival(:readonly => true)
    # check conditions for safe archiving
    base.before_archive :check_for_archive_blockers
    base.before_destroy :check_destroyable
    base.before_update :prevent_update_for_archived_entities
    base.after_unarchive :set_unarchive_flag
    base.after_commit :move_to_bottom_on_unarchive
    #FIXME:In Rails 3 we can see if there is a uniqueness validator and based on that we can add the callbacks for unarchival
    # http://davidsulc.com/blog/2011/05/01/self-marking-required-fields-in-rails-3/
    #object.class.validators_on(method).map(&:class).include? ActiveModel::Validations::UniquenessValidator
  end

  def check_for_archive_blockers
    if can_be_archived?
      # only test this if model has a name
      if self.respond_to?(:name)
        replacement_str=' [archived ' + Time.now.to_s(:db) + ']'
        substn_string=self.name.sub /[ ]\[[a][r][c][h][i][v][e][d][\w -]*[:\d+ ]*\]/,replacement_str #an unsuccessful substitution returns nil aka false
        if substn_string!=self.name
          self.name=substn_string
        else
          self.name=self.name+replacement_str
        end
        self.update_attribute(:name,self.name)
      end
      return true
    else
      raise ActiveRecord::Rollback
    end
  end

  # to be overriden by the individual classes as per requirement
  def can_be_archived?
    false
  end

  # check if the record can be destroyed
  def check_destroyable
    if self.destroyable?
      true
    else
      ## Some generic message to come here
      self.errors[:base] << 'This record has associations and cannot be deleted.'
      false
    end
  end

  # to be overriden by the individual classes as per requirement
  def destroyable?
    can_be_archived? && self.archived?
  end

  # when a model is unarchived, we want it to be at the bottom of the list
  # but since this is a big transaction of its own, this has to be done
  # after the commit stage and only when a flag is set that unarchive was
  # just completed.
  def move_to_bottom_on_unarchive
    if self.just_unarchived
      self.just_unarchived = false
      self.move_to_bottom if self.respond_to?(:move_to_bottom)
    end
    return true
  end

  # because some entities are linked to steps, we need
  # to check for the aasm_state of their parent request
  # in order to run our can be archived test.

# to be called only by models having association with steps
  def count_of_existing_requests_through_step
    req_ids = self.steps.map { |s| s.request_id }.compact.sort.uniq
    count = 0
    while (sub_req_ids = req_ids.slice!(0..(MAX_ITEMS_IN_IN_STATEMENT-1))).size > 0 do
      sub_req_models = Request.functional.find(:all, :conditions => {:id => sub_req_ids})
      count += (sub_req_models.blank? ? 0 : sub_req_models.count)
    end
    return count
  end

 # to be called only by models having association with steps
  def count_of_request_templates_through_steps
    req_ids = self.steps.map { |s| s.request_id }.compact.sort.uniq
    count = 0
    while (sub_req_ids = req_ids.slice!(0..(MAX_ITEMS_IN_IN_STATEMENT-1))).size > 0 do
      sub_req_models = Request.template.find(:all, :conditions => {:id => sub_req_ids})
      ids = sub_req_models.map{|my_req_template| my_req_template.request_template_id}.compact
      unarchived_templates = RequestTemplate.unarchived.extending(QueryHelper::WhereIn).where_in("id", ids).all unless sub_req_models.blank?
      count += (unarchived_templates.blank? ? 0 : unarchived_templates.count)
    end
    return count
  end

  # to be called only by models having association with steps
  def count_of_procedures_through_steps
    self.steps.map{|step| Procedure.unarchived.find_by_id(step.procedure_id)}.compact.uniq.count
  end

  # to be called only by models having association with requests
  def count_of_associated_requests
     self.requests.functional.count
  end

  # to be called only by models having association with requests
  def count_of_associated_request_templates
     self.requests.template.count
  end

  def prevent_update_for_archived_entities
    if self.archived? && !self.archived_at_changed?
      self.errors[:base] << I18n.t('cannot_edit_archived', model_name: self.class.to_s)
      return false
    end
  end

  # a flag to allow us to modify the position after the archiving is done
  def set_unarchive_flag
    self.just_unarchived = true
  end

  def toggle_archive
    success = true
    if archived?
      if self.respond_to?(:aasm_state)
        self.aasm_state = 'retired'
      end
      if success
        return self.unarchive
      else
        return success
      end
    else
      if self.respond_to?(:aasm_state)
        if self.may_archival? || self.aasm_state != 'archived_state'
          begin
            success = self.archival_no_archive!
          rescue
            self.errors[:toggle_archive] << "You cannot archive a " +self.class.to_s.underscore.humanize.downcase+" unless it is in a retired state"
            success = false
          end
        end
      end

      if success
        return self.archive
      else
        return success
      end
    end
  end

end
