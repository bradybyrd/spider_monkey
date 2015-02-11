################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanStage < ActiveRecord::Base
  # TODO: requestor_access here
  attr_accessible :name, :plan_template_id, :plan_template, :position,
                  :auto_start, :requestor_access, :new_status_names, :insertion_point,
                  :request_template_ids, :environment_type_id, :environment_type, :required

  before_destroy :retain_if_has_requests

  belongs_to :plan_template
  belongs_to :environment_type
  has_many :statuses, class_name: 'PlanStageStatus', order: 'plan_stage_statuses.position', dependent: :destroy
  has_many :members, class_name: 'PlanMember', dependent: :nullify
  has_many :requests, through: :members
  has_many :plan_stage_dates, dependent: :destroy
  has_many :plan_stages_request_templates, dependent: :destroy
  has_many :request_templates, through: :plan_stages_request_templates
  has_many :runs, dependent: :destroy, order: 'runs.name'
  has_many :plan_stage_instances, dependent: :destroy


  validates :name, :plan_template_id, :presence => true
  validates :required, :inclusion => { :in => [true, false] }
  validates :name, :uniqueness => { :scope => :plan_template_id, :case_sensitive => false }
  validates :name, :length => { :maximum => 255 }

  acts_as_list :scope => :plan_template_id

  delegate :request_attributes, :to => :request_template, :allow_nil => true

  scope :with_request_template, joins(:request_templates).uniq
  scope :index_order, :order => "plan_stages.name ASC"

  scope :filter_by_environment_type_id, lambda { |filter_value| where(:environment_type_id => filter_value) }

  after_commit :update_plan_stage_instances_for_existing_plans, if: :persisted?

  class << self

    def default_stage
      PlanStage.new(:name => "Unassigned")
    end

  end

  def environment_type_label
    environment_type.try(:label) || 'None'
  end

  def short_name
    name.truncate(20) unless name.blank?
  end

  def strict?
    environment_type.try(:strict) || false
  end

  def plan_stage_instance_for_plan_id(plan_id)
    plan_stage_instances.where(plan_id: plan_id).try(:first)
  end

  # when a plan is created, its asks each stage to create plan members for each associated request template
  def create_plan_members_for_plan(plan)
    # for every request template, create a new plan member and fire its create requests function with the template
    unless plan.nil?
      self.request_templates.includes(request: [:steps]).each do |request_template|
        plan_member = PlanMember.create(:plan_stage_id => self.id, :plan_id => plan.id )
        plan_member.create_request_for_template(request_template)
      end
    end
  end

  def add_requests!(request_ids)
    plan_member_ids = Request.where(:id => request_ids).pluck(:plan_member_id)
    unless plan_member_ids.empty?
      PlanMember.where(:id => plan_member_ids).update_all(:plan_stage_id => self.id)
    end
  end

  def unassign_request!(request_id)
    plan_member_ids = Request.where(:id => request_id).pluck(:plan_member_id)
    unless plan_member_ids.empty?
      PlanMember.where(:id => plan_member_ids).update_all(:plan_stage_id => nil)
    end
  end

  def insertion_point
    self.position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def last_request_of_stage(plan)
    @last_request = members.where(plan_id: plan.id).order(:id).last.request rescue nil
  end


  def previous_required_stage(plan)
    previous_stage = nil
    plan.stages.reverse.each do |stage|
      previous_stage = stage if stage.position < position && stage.required?
      break if previous_stage
    end
    previous_stage
  end

  def next_required_stage(plan)
    next_stage = nil
    plan.stages.each do |stage|
      next_stage = stage if stage.position > position && stage.required? && stage.plan_stage_instance_for_plan_id(plan.id).valid_for_promotion?
      break if next_stage
    end
    next_stage
  end

  private

  # when a plan stage is added to a plan template, we need to check if any plans have been created based
  # on that template and add a plan stage instance for them
  def update_plan_stage_instances_for_existing_plans
    plans = plan_template.plans || []
    plans.each do |plan|
      self.plan_stage_instances.find_or_create_by_plan_id(plan.id)
    end
    true
  end

  # before destroy hook to keep stages with associated plans from being deleted
  def retain_if_has_requests
    if self.requests.blank?
      true
    else
      #destroy relation plan_stages_request_templates
      self.plan_stages_request_templates.destroy_all
      self.errors.add(:requests, " exist for this plan stage; deletion is not allowed.")
      false
    end
  end

end
