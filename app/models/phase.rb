################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Phase < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt
  
  normalize_attributes :name

  has_many :runtime_phases, :order => :position ,:dependent => :destroy
  has_many :steps
  
  validates :name,
            :presence => true,
            :uniqueness => true
  
  

  scope :in_order, order('phases.position')

  acts_as_list :scope => 'archived_at IS NULL'

  before_destroy :destroyable?

  attr_accessible :name, :insertion_point, :step_ids, :runtime_phase_ids
  
  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }
  
  # may be filtered through REST
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

 
  def set_runtime_phases(names)
    return if !names || self.archived?

    (runtime_phase_names - names).each do |old_name|
      old_runtime_phase = runtime_phases.find_by_name(old_name)
      old_runtime_phase.destroy if old_runtime_phase
    end

    names.reverse_each do |name|
      next if name.blank? || runtime_phase_names.include?(name)
      runtime_phases.build :name => name, :phase => self
    end
  end

  def runtime_phase_names
    runtime_phases.map { |rp| rp.name }
  end

  def can_be_archived?
    (count_of_existing_requests_through_step_and_execution_conditions == 0) \
     && (count_of_request_templates_through_steps_and_execution_conditions == 0) \
     && (count_of_procedures_through_steps ==0)
  end

  def count_of_existing_requests_through_step_and_execution_conditions
    req_ids1 = self.steps.map { |s| s.request_id }

    req_ids2 = Phase.select('requests.id').
        joins(:runtime_phases => {:step_execution_conditions => {:step => :request}})
        .where(:id => self.id).map(&:id)

    req_ids = (req_ids1 + req_ids2).compact.sort.uniq
    count = 0
    while (sub_req_ids = req_ids.slice!(0..(MAX_ITEMS_IN_IN_STATEMENT-1))).size > 0 do
      sub_req_models = Request.functional.find(:all, :conditions => {:id => sub_req_ids})
      count += (sub_req_models.blank? ? 0 : sub_req_models.count)
    end
    return count
  end

  # to be called only by models having association with steps
  def count_of_request_templates_through_steps_and_execution_conditions
    req_ids1 = self.steps.map { |s| s.request_id }

    req_ids2 = Phase.select('requests.id').
        joins(:runtime_phases => {:step_execution_conditions => {:step => :request}})
        .where(:id => self.id).map(&:id)

    req_ids = (req_ids1 + req_ids2).compact.sort.uniq
    count = 0
    while (sub_req_ids = req_ids.slice!(0..(MAX_ITEMS_IN_IN_STATEMENT-1))).size > 0 do
      sub_req_models = Request.template.find(:all, :conditions => {:id => sub_req_ids})
      unarchived_templates = RequestTemplate.unarchived.find(:all,:conditions => ["id IN (?)",sub_req_models.map{|my_req_template| my_req_template.request_template_id}.compact]) unless sub_req_models.blank?
      count += (unarchived_templates.blank? ? 0 : unarchived_templates.count)
    end
    return count
  end

end

