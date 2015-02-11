################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'sortable_model'

class PlanMember < ActiveRecord::Base

  # blocking access to aasm_state
  attr_accessible :plan_stage_id, :plan_stage_status_id, :created_at,
                  :updated_at, :plan_id, :position, :run_id, :parallel,
                  :different_level_from_previous, :stage, :run, :status,
                  :plan, :insertion_point

  acts_as_list :scope => :run #'plan_id=#{plan_id} and plan_stage_id=#{plan_stage_id || 0}'

  belongs_to :plan
  belongs_to :run
  belongs_to :stage, :class_name => 'PlanStage', :foreign_key => :plan_stage_id
  belongs_to :status, :class_name => 'PlanStageStatus', :foreign_key => :plan_stage_status_id
  # technically, this should be a has_one relationship.  Rails 2.3.x has some defects in the handling
  # of joins around has_one relationships (erroneously asks for source to be identified and produces invalid SQL)
  # so this is a has_many with a method based singular getter and setter added for convenience below
  has_one :request, :dependent => :nullify
  has_one :environment, :through => :request

  validates :plan_id,:presence => true

  scope :for_request_aasm_state, lambda { |aasm_state| joins(:request).where("requests.aasm_state" => aasm_state) }

  scope :for_stage, lambda { |plan_stage_id| where("plan_stage_id = ?", plan_stage_id) }

  # FIXME: This should be a scope with a lamda and be checked for efficiency
  def self.entitled(user)
    # TODO: should be clarified
    if (user.in_root_group? || user.can?(:inspect, Plan.new))
      self
    else
      joins(:request).where('requests.id' => user.requests)
    end
  end

  def self.available_for(plan)
    plan_id = plan.is_a?(Plan) ? plan.id : plan
    where("plan_id IS NULL OR plan_id = ?", plan_id)
  end

  scope :for_plans, lambda { |lc_ids| where('plan_id' => lc_ids) }

  scope :for_requests, lambda { |request_ids| joins(:request).where('requests.id' => request_ids) }

  scope :run_execution_order, order('plan_members.run_id ASC, plan_members.position ASC')

  delegate :plan_template, :plan_template_id, :to => :plan, :allow_nil => true

  sortable_model

  can_sort_by :request_aasm_state, lambda { |asc| includes(:request).order("requests.aasm_state #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_id, lambda { |asc| includes(:request).order("requests.id #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_name, lambda { |asc| includes(:request).order("requests.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_owner_name, lambda {|asc| includes(:request => :owner).
            order("users.first_name #{asc ? "ASC" : "DESC"}, users.last_name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_app, lambda { |asc| includes(:request => :apps).order("apps.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_app_and_environment, lambda { |asc| includes(:request => :apps).includes(:request => :environment).
            order("apps.name #{asc ? "ASC" : "DESC"}, environments.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_environment, lambda { |asc| includes(:request => :environment).order("environments.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_scheduled_at, lambda { |asc| includes(:request).order("requests.scheduled_at #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_target_completion_at, lambda { |asc| includes(:request).order("requests.target_completion_at #{asc ? "ASC" : "DESC"}") }

  can_sort_by :request_created_at, lambda { |asc| includes(:request).order("requests.created_at #{asc ? "ASC" : "DESC"}") }

  can_sort_by :executable_step_count, lambda { |asc|
    select("#{PlanMember.groupable_column_names}, count(steps.id)").
    joins("LEFT JOIN requests ON requests.plan_member_id = plan_members.id LEFT JOIN steps ON steps.request_id = requests.id ").
    where("steps.procedure = ? OR steps.procedure IS NULL", false).
    order("count(steps.id) #{asc ? "ASC" : "DESC"}").
    group(PlanMember.groupable_column_names)
  }

  can_sort_by :request_duration, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    time_diff = if OracleAdapter
      "(coalesce(requests.completed_at,requests.started_at,sysdate) - coalesce(requests.started_at,requests.completed_at,sysdate))"
    else
      "(coalesce(requests.completed_at, requests.started_at, current_timestamp) - coalesce(requests.started_at, requests.completed_at, current_timestamp))"
    end
    includes(:request).order("#{time_diff} #{order}")
  }

  can_sort_by :run_name, lambda { |asc| includes(:run).order("runs.name #{asc ? "ASC" : "DESC"}") }

  # when the object is sent a new stage, we need to move it to the bottom
  def update_attributes(attributes)
    # reorder the positions if the plan_stage has changed
    unless attributes[:plan_stage_id].blank? || attributes[:plan_stage_id].to_i==self.plan_stage_id.to_i
      reorder_positions(attributes[:plan_stage_id])
      #this is needed to get rid of the old params[:position]
      attributes.delete("position")
    end
    super(attributes)
  end

  # when a new plan is created, a callback starts a chain
  # of simple, encapsulated calls, checking each stage, finding
  # related request_templates, then constructing plan_members
  # and finally (here) make the call to build the template. Each
  # class does the work it knows how to do
  def create_request_for_template(request_template)
    if request_template
      # provide some plan specific defaults
      # protect against no user conditions
      user = User.current_user || User.root_users.first
      request_default_params = { :request => { :requestor_id => user.try(:id),
          :owner_id => user.try(:id),
          :name => "#{self.plan.try(:name)}: #{self.stage.try(:name)}",
          :should_time_stitch => true,
          :plan_member_attributes => {
            :plan_id => plan_id,
            :plan_stage_id => plan_stage_id
          },
        },
        :include => {:users => true},
        :request_template_id => request_template.id,
        :validation_skippers => [:skip_check_if_able_to_create_request_validation]
      }
      # set some sensible default values
      new_request = request_template.create_request_for(User.current_user, request_default_params)
      self.request = new_request

      if self.request.present?
        self.request.app_ids.each do |appid|
          p = PlanEnvAppDate.where("app_id = ? and environment_id = ? and plan_id = ?", appid, self.request.environment_id, self.plan_id).all
          PlanEnvAppDate.create(:app_id=> appid, :environment_id => self.request.environment_id, :plan_id => self.plan_id, :plan_template_id => '1' , :created_at => Time.now, :created_by => User.current_user.id) if (p.size == 0)
        end
      end

      self.request
    end
  end

  def insertion_point
    self.position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def promote!
    next_stage = stage.lower_item
    if next_stage && self.stage != next_stage
      self.stage = next_stage
      self.save!
      self.move_to_bottom
    end
  end

  def demote!
    previous_stage = stage.higher_item
    if previous_stage && self.stage != previous_stage
      self.stage = previous_stage
      self.save!
      self.move_to_bottom
    end
  end

  # class method to change the positions of two lifecyle
  # members, usually because one was dropped on another, or a new stage
  # with no members if provided
  # FIXME: member are now reordered in RUns so this either needs to
  # removed or redone.
  def move_to_member_or_stage(member_to_target_id = 0, passed_stage_id = 0)
    success = false

    # the target might be nil, in which case we need a stage
    member_to_target = PlanMember.find(member_to_target_id) rescue nil

    # prefer the member target stage, but use the passed one if that fails
    new_stage_id = member_to_target.try(:plan_stage_id) || passed_stage_id

    # get the stage and bomb if not found
    new_stage = self.plan.stages.find(new_stage_id) rescue nil

    # sanity check that the stage is valid for the plan
    unless new_stage.nil?
      #sanity check that the target is of the same plan
      unless !member_to_target.nil? && member_to_target.try(:plan_id) != self.plan_id
        # update the stage unless it is already the same value
        saved = true
        unless self.plan_stage_id == new_stage_id
          # if we are changing stages, first remove it from the current set
          self.move_to_bottom
          # then change the scope to the new plan
          saved = self.update_attributes(:plan_stage_id => new_stage_id)
        end
        # now finally adjust the position or set to 1
        if member_to_target.try(:position)
          self.insert_at(member_to_target.try(:position))
        else
        self.move_to_bottom
        end
      success = true if saved
      end
    else
    # if no stage, make it unassigned
      success = self.update_attributes(:plan_stage_id => 0)
    end

    return success
  end

  # a routine to heal and gaps in the position for runs of null runs in a stage
  def heal_positions
    if self.run
    members = self.run.plan_members.run_execution_order
    else
      members = self.plan.members.includes(:stage).where('plan_members.run_id is null').order('plan_stage.position, plan_members.position ASC, created_at ASC')
    end
    unless members.blank?
      members.each_with_index do |member, index|
        member.update_attribute(:position, index + 1)
      end
    end
  end

  private

  def reorder_positions(new_stage_id)
    # reorder source list
    self.remove_from_list
    # find the max position in the destination list
    self.position = PlanMember.find(:first, :select => 'MAX(position) as max_position', :conditions => {:plan_stage_id => new_stage_id, :plan_id => self.plan_id}).max_position.to_i + 1
  end

  def self.groupable_column_names
    return PlanMember.column_names.map { |c| "plan_members.#{c}" }.join(",")
  end

end
