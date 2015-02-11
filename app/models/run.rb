class Run < ActiveRecord::Base

  attr_accessible  :aasm_event, :request_ids, :name, :start_at, :end_at, :duration,
                  :description, :requestor_id, :owner_id, :plan_id, :plan_stage_id,
                  :plan_stage, :owner, :plan, :requestor, :owner, :requests, :plan_members,
                  :start_at_date, :start_at_hour, :start_at_minute, :start_at_meridian,
                  :end_at_date, :end_at_hour, :end_at_minute, :end_at_meridian,:requests_planned_date,
                  :auto_promote, :next_stage_promotion

  # FIXME: This cannot be the best way to handle dates and time zones in Rails 3??????
  # causes my tests to fail so I am commenting it out and will work with the interface
  # and a proper date picker to make dates work like normal rails apps through utc
  # and localization
  include ExposedTime
  # before_validation :reformat_dates_to_us_format
  before_validation :stitch_together_start_at,:stitch_together_end_at, :if => :should_time_stitch
  expose_time_for_selector :start_at, :end_at

  concerned_with :run_state_machine
  concerned_with :run_named_scopes

  normalize_attributes :name, :description

  belongs_to :plan
  belongs_to :plan_stage
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :requestor, :class_name => "User", :foreign_key => "requestor_id"
  # by setting dependent to nullify, requests stay in the plan and stage, but
  # are no longer associated with the deleted run
  has_many :plan_members, :dependent => :nullify
  has_many :requests, :through => :plan_members

  validates :name,
            :presence => true,
            :length =>{:maximum => 255},
            :uniqueness => {:scope => [:plan_id, :plan_stage_id]}
  validates :description,
            :length =>{:maximum => 255, :allow_blank => true }

  validates :requestor_id, :presence => true
  validates :owner_id,  :presence => true
  validates :plan_id, :presence => true

  validates :duration,
            :numericality => {:less_than => 10000, :only_integer => true, :allow_nil => true, :message => " should be an integer less than 10,000."}

  # look for an "magic" event properties that run state changes,
  # if successful, these will be run after save
  validate :validate_aasm_event, :if => Proc.new {|r| r.aasm_event.present?}
  validate :validate_scheduling
  validate :validate_can_start

  attr_accessor :aasm_event, :request_ids, :should_time_stitch, :requests_planned_date,
                :start_at_to_earliest_planned_at, :request_planned_at_to_run_start_at, :next_stage_promotion,
                :executable_event

  after_save :build_associated_requests, :unless => Proc.new {|r| r.request_ids.blank?}
  after_update :run_aasm_event, :if => Proc.new {|r| r.aasm_event.present?}
  after_create :push_msg

  def date_label
    my_label = []
    my_label << (self.start_at.blank? ? "--" : self.start_at.try(:default_format_date))
    my_label << (self.end_at.blank? ? "--" : self.end_at.try(:default_format_date))
    my_label.join(" <-> ")
  end

  # as a DE89232 a question appeared: why not to destroy the run when it can't to available within app any more?..
  # # user the state machine as a soft delete mechanism
  # def destroy
  #   self.delete! unless self.aasm_state == "deleted"
  # end

  # supports parallel levels and drag and drop reordering
  def each_member_level
    rval_members = []
    level = 1

    self.plan_members.run_execution_order.each do |member|
      if member.different_level_from_previous?
        unless rval_members.empty?
        yield(rval_members, level)
        level += 1
        end
        rval_members = [member]
      else
      rval_members << member
      end
    end

    yield(rval_members, level)
  end

  def set_scheduled_date(request, scheduled_date_for_cloned_request)
    unless scheduled_date_for_cloned_request.except("environment_id").values.join('').empty?
      request.should_time_stitch = true
      end_date = request.target_completion_at
      logger.info("RIGHT HERE NOW _-- STITCHING DATES")
      request.attributes = scheduled_date_for_cloned_request.except("environment_id")
      request.stitch_together_scheduled_at
      request.should_time_stitch = false
      request.update_attribute(:target_completion_at, end_date)
      request.update_attribute(:target_completion_at, request.scheduled_at + 60) if can_set_due_date(request)
    else
      request.should_time_stitch = false
      request.auto_start = false if start_at.nil?
      request.scheduled_at = start_at
      request.update_attribute(:target_completion_at, start_at + 60 ) if can_set_due_date(request)
    end
    # TODO: Needs refactoring to do proper request creation for run with or w/o route gate constraints
    request.save(validate: false)
  end

  def can_set_due_date(request)
    (request.due_before_scheduled? || request.target_completion_at.nil?) && request.scheduled_at.present?
  end

  def requests_have_notices?
    self.requests.each{|r| return true if r.has_notices? }
    false
  end

  def requests_notices_message
    msg = self.requests.map{|r| r.has_notices? ? "Request #{r.number}: #{r.notices.join(', ')}" : next }.compact.uniq
    msg.join(";\n") unless msg.empty?
  end

  def validate_can_start
    policy  = RunPolicy.new self
    policy.validate_can_start
  end

  private

  def validate_aasm_event
    self.executable_event ||= AasmEvent::ExecuteEvent.new(self)
    self.executable_event.validate_aasm_event
  end

  # if an aasm_event was passed through parameters on an update or create with no errors, then run it
  def run_aasm_event
    # make sure the is a command waiting to run and there are no errors on it.
    self.executable_event.run_aasm_event if self.errors[:aasm_event].blank?
  end

  def validate_scheduling
    if self.end_at.present? && self.start_at.present?
      if self.end_at < self.start_at
        self.errors.add(:end_at, " can not be earlier than start at")
      end
    end
    if self.requests_planned_date.present?
      self.requests_planned_date.each do |key, value|
        date_ymd = value[:scheduled_at_date]
        hour = value[:scheduled_at_hour]
        min = value[:scheduled_at_minute]
        meridian = value[:scheduled_at_meridian]
        date = "#{date_ymd} #{hour}:#{min} #{meridian}"
        if self.start_at.present? && Time.zone.parse(date).present?
          if self.start_at > Time.zone.parse(date)
            self.errors.add(:start_at, "can not be after request planned at") && return
          end
        end
      end
    end
  end

  def change_planned_date?
    (requests_planned_date.present? || start_at_to_earliest_planned_at || request_planned_at_to_run_start_at)
  end

  # after creation, we should have request ids that need to be linked through members
  def build_associated_requests
    # make sure we have requests passed in from the form
    unless self.request_ids.blank?
      # purge any requests already in the run
      request_ids_to_find = self.request_ids.reject { |id| self.requests.map(&:id).include?(id) }.uniq.sort
      #find the plan members for those requests scoped by this plan
      member_ids = PlanMember.for_requests(request_ids_to_find).map(&:id)
      members = PlanMember.find(member_ids)
      # cache the current number of members linked to the request
      current_member_count = self.plan_members.try(:count) || 0
      # this should not fail to find members, but double check
      unless members.blank?
        members.each_with_index do |member, index|
          # check if it is associated with a run already OR from another stage in which case we want to copy it
          unless member.request.should_be_cloned?(self.plan_stage_id, true)
            if change_planned_date?
              scheduled_date_for_cloned_request = requests_planned_date.values_at(member.request.id.to_s).first
              set_scheduled_date(member.request, scheduled_date_for_cloned_request)
            end
            old_position = member.position
            member.update_attributes(:run_id => self.id)
          else
            request_to_clone = member.request
            scheduled_date_for_cloned_request = requests_planned_date.values_at(request_to_clone.id.to_s).first if change_planned_date?
            if request_to_clone
              request_params = { request: { name: member.request.request_label + " (#{Time.now.to_s(:long)})",
                                            environment_id: scheduled_date_for_cloned_request['environment_id'],
                                            from_run: true,
                                            plan_member_attributes: { plan_id: self.plan_id,
                                                                      plan_stage_id: self.plan_stage_id } },
                                 include: { :all => true } }
              cloned_request = request_to_clone.clone_via_template(self.requestor, request_params)
              cloned_request.update_attribute(:parent_request_id, request_to_clone.id) if next_stage_promotion
              set_scheduled_date(cloned_request, scheduled_date_for_cloned_request) if change_planned_date?

              # It is important to reload the object else the changes made to the request are not reflected completely
              #This was leading to problems while cloning ticket when the steps within procedure were not reflected while iterating over
              #request.
              cloned_request.reload

              if cloned_request.blank?  || cloned_request.plan_member.blank? || !cloned_request.plan_member.update_attributes(:run_id => self.id)
                self.errors.add(:request_ids, "could not be created because of a problem cloning request id #{request_to_clone}.")
              else
              # move the new request to the bottom of the stage
                cloned_request.plan_member.move_to_bottom
                # because we are in a run cloning situation, we know the plans are the same and can safely clone tickets as well after sanity test to
                # make sure all is well with the clone in terms of matching step counts
                # steps_to_clone = request_to_clone.steps.order_by_position.all
                steps_to_clone = request_to_clone.steps.sort_by(&:number)
                if !cloned_request.steps.blank? && !steps_to_clone.blank? && (cloned_request.steps.count == steps_to_clone.count)
                  # cycle through the two requests by step and copy over the tickets
                  cloned_request.steps.sort_by(&:number).each_with_index do |cloned_step, step_index|
                    step_to_clone = steps_to_clone[step_index]
                    cloned_step.tickets << step_to_clone.tickets if step_to_clone && !step_to_clone.tickets.blank?
                  end
                end
              end
            else
              self.errors.add(:request_ids, "could not be created because plan member #{member.id} has no associated request to clone.")
            end
          end
        end
      else
        self.errors.add(:request_ids, "could not be created because of a problem finding related plan members.")
      end
    end
    # and blank out the passed ids so we don't repeat the treatment in case this hook moves someplace where it is run again
    self.request_ids = []
    self.should_time_stitch = false
    self.update_attribute(:start_at, self.reload.requests.map(&:scheduled_at).compact.sort { |x, y| x <=> y }.first) if start_at_to_earliest_planned_at
  end
end
