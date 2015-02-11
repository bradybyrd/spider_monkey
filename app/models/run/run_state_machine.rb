################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
class Run < ActiveRecord::Base

  include AASM
  include Messaging
  acts_as_messagable


  aasm do
    state :created, :initial => true
    state :planned
    state :started
    state :held
    state :blocked
    state :completed
    state :cancelled
    state :deleted,  :enter => :prepare_for_deletion

    event :created, :success => :push_msg do
      transitions :to => :created, :from => [:created]
    end

    event :plan_it, :success => [:plan_requests, :push_msg] do
      transitions :to => :planned, :from => [:created, :cancelled]
    end

    event :start, :success => [:start_next_eligible_request, :push_msg] do
      transitions :to => :started, :from => [:held, :planned, :blocked]
    end

    event :block, :success => :push_msg do
      transitions :to => :blocked, :from => [:started]
    end

    event :hold, :success => [:hold_eligible_requests, :push_msg] do
      transitions :to => :held, :from => [:started]
    end

    event :complete, :success => [:check_for_auto_promote, :push_msg] do
      transitions :to => :completed, :from => [:started]
    end

    event :cancel, :success => [:cancel_requests, :push_msg] do
      transitions :to => :cancelled, :from => [:created, :planned, :started, :held, :blocked]
    end

    event :delete, :success => :push_msg do
      transitions :to => :deleted, :from => [:created, :cancelled, :completed]
    end
  end

  def self.status_filters_for_select
    aasm.states.map { |state| [state.name.to_s.humanize, state.name.to_s] }
  end

  # a convenience method for seeing if the run is in one of the active states that need monitoring
  def running?
    ['started', 'blocked'].include?(self.aasm_state)
  end

  def prepare_for_deletion
    # before moving to the deleted state, adjust the name so it has the date and does not
    # cause a uniqueness violation by holding onto a usable name or fail to update because it has grown too long.
    new_name = (self.name.length > 200 ? "#{self.name[0..200]}... " : self.name)
    new_name = "#{new_name} [deleted #{Time.now.to_s(:db)}]"
    success = self.update_attribute(:name, new_name)
    # put in a fail safe if something went wrong
    unless success
      # pick something whose length and uniqueness is known and should not cause an error
      success = self.update_attribute(:name, "Renamed on Update Error [deleted #{Time.now.to_s(:db)}]")
    end
    # nullify any related plan members to free them up
    PlanMember.update_all("run_id = NULL", "run_id = #{self.id}")
  end

  def plan_requests
    self.plan_members.run_execution_order.each do |lm|
      request = lm.request
      request.plan_it! if request && request.aasm.events(request.aasm.current_state).include?(:plan_it)
    end
  end

  # TODO: Do we need instance variable here?
  def cancel_requests
    self.plan_members.run_execution_order.each do |lm|
      request = lm.request
      if request && request.aasm.events(request.aasm.current_state).include?(:cancel)
        @request = request
        @request.cancel!
      end
    end
  end

  def start_next_eligible_request(passed_request = nil)
    request_to_start = passed_request || next_request_eligible_for_event(:start)
    unless request_to_start.blank?
      # start this first one
      # FIXME: The request state machine transition logic has been spread out between the requests controller,
      # the request model call backs, and some new special methods to support remote starting.  This should all
      # be factored (especially the controller bits) to rely on the :success parameter of each transition state
      # so we can use the original state machine verbs (start!, etc) and have the same behavior from all sides.

      #request_to_start.start_request!
      RequestService::RequestStarter.new(request_to_start).within(:run).start_request!

      # check the next member request to see if it is parallel
      start_next_parallel_member(request_to_start.plan_member)
    else
      self.check_status
    end
  end

  def start_next_parallel_member( previous_member )
    old_position = previous_member.position
    next_member = self.plan_members.run_execution_order.find(:first, :conditions => ['plan_members.position > ?', old_position])
    if next_member && !next_member.different_level_from_previous
      start_next_eligible_request(next_member.request)
    end
  end

  def hold_eligible_requests
    try_event_for_all_eligible_requests(:put_on_hold)
  end

  def try_event_for_all_eligible_requests(request_event)
    # get the next eligible event for this request
    next_request = next_request_eligible_for_event(request_event)
    while next_request != nil
      # send the event to the request
      next_request.send("#{request_event}!")
      # load the next available request, exiting if nil
      next_request = next_request_eligible_for_event(request_event)
    end
    # check the status of the run in case anything bubbles up
    self.check_status
  end

  def first_request
    return self.plan_members.run_execution_order.first.request unless self.plan_members.blank?
  end

  # look for the next request that is eligible
  def next_request_eligible_for_event(request_event)
    results = nil
    previous_lm = nil
    self.plan_members.run_execution_order.each do |lm|
    # see if the current request state can handle this event
      request = lm.request
      if request.aasm.events(request.aasm.current_state).include?(request_event)
        results = request unless previous_lm && previous_lm.request.try(:aasm_state) == 'started' && lm.different_level_from_previous
        break
      else
        case request_event
        when :start
         #for below condition:you do not try to start parallel requests from here and in
         #other cases it is always good to prevent start of newer requests when the first request is not complete
          break if previous_lm == nil && request.try(:aasm_state) == 'started'
          break if previous_lm && previous_lm.request.try(:aasm_state) == 'started'

        end
        previous_lm = lm
      end
    end
    # if we reached here, we have not returned for any eligible run and should check overall status
    return results
  end

  ################################
  # REPORTING FUNCTIONS
  ###############################

  # a routine to check the current status when there are blockages or no more work to be done
  def check_status
    # only check the status if running
    if self.running?
      # first check to see if anyone is blocked
      total_blocked = blocked_requests_count
      if total_blocked > 0 && self.aasm.events(self.aasm.current_state).include?(:block)
        self.block!
      elsif total_blocked == 0 && self.blocked?
        self.start!
      elsif self.started?
        # check for all complete
        total_members     = self.plan_members.count
        completed_members = self.requests.complete.count
        if total_members == completed_members && self.aasm.events(self.aasm.current_state).include?(:complete)
          self.complete!
        else
          #check for others to start up
          currently_running = self.requests.started.count + self.requests.hold.count + self.requests.problem.count
          eligible_to_start = self.requests.planned.count
          start_next_eligible_request if currently_running == 0 && eligible_to_start > 0
        end
      end
    end
    # check for anything new and move it to at least planned if running or planned
    plan_new_requests
  end

  def blocked_requests_count
    self.requests.problem.count + self.requests.hold.count # + self.requests.with_auto_start_errors.count
  end

  def plan_new_requests
    if self.planned? || self.running?
      #move anything newly created to planned
      newly_created = self.requests.created
      unless newly_created.blank?
        newly_created.each do |request|
          request.plan_it!
        end
      end
    end
  end

  ##############################
  # INCOMING MESSAGES
  # FIXME: Consider message system
  ###############################
  def request_completed(request)
    # sanity check that this is a request and it's run is the same as self
    if request && request.try(:run) == self && self.started?
      start_next_eligible_request
    end
  end

  def check_for_auto_promote
    logger.info("############################### starting auto promote loop")
    success = true
    if auto_promote?
      # see if there is a next required stage
      next_required_stage = plan_stage.next_required_stage(plan)
      if next_required_stage.present?
        request_ids_to_clone = requests.complete.all.try(:map, &:id).compact
        if request_ids_to_clone.present?
          # horrible hack to reuse select_run_for_ammendment form logic
          # where the planned date hash is repurposed as a request
          # customization container
          requests_planned_date = set_new_environment(next_required_stage, request_ids_to_clone)

          # build the run with the passed parameters
          new_run = Run.create(:plan => plan,
                               :plan_stage => next_required_stage,
                               :requestor => requestor,
                               :owner => owner,
                               :description => description,
                               :duration => duration,
                               :name => name,
                               :auto_promote => auto_promote,
                               :requests_planned_date => requests_planned_date,
                               :request_ids => request_ids_to_clone,
                               :next_stage_promotion => true)

          logger.info("############################### new_run: #{new_run.inspect}")
          if new_run.try(:valid?)
            new_run.plan_it!
            new_run.start!
          end
        end
      end
      logger.info("############################### ending auto promote loop")
      success
    end
  end

  def set_new_environment(next_required_stage, request_ids_to_clone)
    request_customizer = {}
    plan_stage_instance =  next_required_stage.plan_stage_instance_for_plan_id(plan_id)
    if plan_stage_instance.present?
      request_ids_to_clone.each do |request_id|
        request = Request.find(request_id)
        if request.present?
          default_environment =  plan_stage_instance.try(:allowable_environments_for_request, request).try(:first)
          request_customizer[request_id.to_s] = {}
          request_customizer[request_id.to_s]['environment_id'] = default_environment.try(:id)
        end
      end
    end

    logger.info("############################### request_customizer: #{request_customizer.inspect}")
    request_customizer
  end
end
