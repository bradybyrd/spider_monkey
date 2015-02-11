################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class ChangeRequest < ActiveRecord::Base

  belongs_to :plan
  belongs_to :project_server
  belongs_to :query

  has_many :steps, :dependent => :nullify

  has_many :step_holders, :dependent => :destroy

  Fields = [:sys_id,
    :cg_no,
    :u_application_name,
    :short_description,
    :u_cc_environment,
    :category,
    :u_config_items_list,
    :u_stage,
    :cr_state,
    :start_date,
    :end_date,
    :approval,
    :u_version_tag,
    :u_pmo_project_id,
    :assignment_group,
    :u_service_affecting,
    :u_code_synch_required,
    :cr_type,
    :risk]

  TextAreaFields = [:description,
    :change_plan,
    :test_plan,
    :backout_plan,
    :u_release_notes]

  before_save :stringify_attributes!

  acts_as_audited
  
  #CHKME: CF: I don;t have time to figure out all the unusual scope like calls for this model
  # and its relationship to service now -- but it is crashing on plan request creation so 
  # putting it in some working form
  scope :ascend_by_cg_no, order('cg_no ASC')

  attr_reader :ci_tokens

  class << self
        def with_query_id(query_id)
      if query_id.to_i == 0
        where(:query_id => nil)
      else
        where(:query_id => query_id)
      end.ascend_by_cg_no
    end

    def labels
      { :sys_id => "Sys ID",
        :cg_no => "Change Request #",
        :short_description => "Short Description",
        :description => "Description",
        :change_plan => "Change Plan",
        :backout_plan => "Backout Plan",
        :test_plan => "Test Plan",
        :category => "Category",
        :u_application_name => "Application",
        :u_stage => "Stage",
        :cr_state => "State",
        :start_date => "Planned Start Date",
        :end_date => "Planned End Date",
        :approval => "Approval",
        :u_version_tag => "Version Tag",
        :u_pmo_project_id => "PMO Project ID",
        :u_cc_environment => "Environment",
        :assignment_group => "Assignment Group",
        :risk => "Change Impact Criteria",
        :u_service_affecting => "Service Affecting",
        :u_code_synch_required => "CODE Synch Required",
        :u_config_items_list => "CI (Server)",
        :u_release_notes => "Release Notes",
        :cr_type => "Type"
      }
    end

    def label_name_for(attribute)
      labels[attribute]
    end

    def save_locally(attributes, step)
      if attributes[:id].present?
        change_request = find(attributes[:id])
        update_step_holders = true
        modified_attributes = {}
        attrs = {}
        modified_attributes.merge!(attributes)
        cg_req = find(attributes[:id].to_s.to_i)
        modified_attributes.each {|key, value|
          value = value.blank? ? ( cg_req[key].blank? ? modified_attributes[key]  = cg_req[key] : modified_attributes[key]  = nil ) : value
        }
        modified_attributes.delete_if {|key, value| key == "save_remotely" || key == "cr_state" || key == "risk"}
        attrs = cg_req.set_attribute_values(attributes.symbolize_keys)
        if attrs[:u_cc_environment] == cg_req.u_cc_environment && attrs[:assignment_group] == cg_req.assignment_group && attrs[:u_pmo_project_id] == cg_req.u_pmo_project_id
        update_step_holders = false
        end
        modified_attributes = cg_req.set_attribute_values(modified_attributes.symbolize_keys)
        cg_req.attributes = modified_attributes
        if cg_req.changed?
          new_attributes = {}
          new_attributes = cg_req.set_attribute_values(attributes.symbolize_keys)
          update_step_holders = update_step_holders ? true : false
          change_request.attributes = update_step_holders ? new_attributes : modified_attributes
        else
        update_step_holders = false
        change_request.attributes = modified_attributes
        end
      else
        attrs = {}
        change_request = new(attrs)
        attrs = change_request.set_attribute_values(attributes.symbolize_keys)
        update_step_holders = true
        change_request.attributes = attrs
      end
      if plan_id = step.request.plan_member.present?
        change_request.plan_id = step.request.plan_member.plan_id
      end
      change_request.tab_id = 2 # From Plan::TABS. It is always 2 for Operations Tickets
      change_request.show_in_step = true
      change_request.save
      unless step.new_record?
        step.update_attributes(:change_request_id => change_request.id)
      end
      if update_step_holders
        sh = StepHolder.find_or_create_by_step_id_and_change_request_id(step.id, change_request.id)
        sh.update_attributes(:request_id => step.request.id )
      end
      change_request.id
    end
  end

  def label
    cg_no.blank? ? short_description : "#{cg_no}::#{short_description}"
  end

  def step_holder_label(step, request)
    cg_no.blank? ? "[#{request.number}##{step.number}] - #{short_description}" : label
  end

  def check_label(request,step)
    if step.new_record?
      if request.steps.present?
        request_change_id = request.steps.map(&:change_request_id).present? ? request.steps.map(&:change_request_id).compact.first : ""
        step_id = StepHolder.request_id_equals(request.id).map(&:step_id).first
        step = Step.find(step_id).present? ? Step.find(step_id) : step  if step_id.present?
        StepHolder.find_by_request_id(request.id).present? ? step_holder_label(step,request) : label
      else
        label
      end
    else
      step_id = StepHolder.request_id_equals(request.id).map(&:step_id).first
      step  = step_id.present? ? Step.find_by_id(step_id) || step : step
      StepHolder.find_by_request_id_and_step_id(request.id,step.id).present? ? step_holder_label(step,request) : label
    end
  end

  def created_remotely?
    !not_created_remotely?
  end

  def not_created_remotely?
    cg_no.blank?
  end

  def number
    cg_no
  end

  def number=(value)
    self[:cg_no] = value
  end

  def ci_tokens=(ids)
    self["u_config_items_list"] = ids
  end

  # this function is used by the tokenizer to load valid service now data or placeholders
  # into the token field based on the ci_items_list comma separated string saved in the service now remote
  # record and the change_request cached field.  The challenge is to never lose remote data even if
  # our local cache is out of date or does not include a valid ci_item that is not a server.
  def ci_tokens_lookup
    # always return at least a blank array, even if other things do not go right
    results = []
    # check if the config items list is blank
    unless self.u_config_items_list.blank?
      # find the currently saved config items, not all of which might be in service now data
      saved_ids = self.u_config_items_list.split(",")
      # if there are some, try to find them or put in place holders
      unless saved_ids.blank?
        # try to find matching ones in service now data, returning an empty array if none found
        matching_service_now_data = ServiceNowData.find_all_by_sys_id(saved_ids).map { |s| { :id => s.sys_id, :name => s.name } }
        #logger.info "####### matching_service_now_data " + matching_service_now_data.inspect
        # find out if all the remote ids can be matched to our cached values by rejecting all the matches and see what is left
        missing_ids = saved_ids
        missing_ids.reject! { |s| matching_service_now_data.map { |m| m[:id] }.include?(s) }
        #logger.info "####### missing_ids: " + missing_ids.inspect
        # if there are missing ids, create a place holder for them so they get preserved in ServiceNow updates
        # by cycling through the missing ids and create a new objects that had a place holder name
        placeholders = (missing_ids.blank? ?  [] : missing_ids.map { |p| { :id => p, :name => "NOT_CACHED: #{p} " }} )
      #logger.info "####### placeholders " + placeholders.inspect
      # add the two arrays together to get the complete set, removing any accidental duplicates (should be none)
      results = matching_service_now_data | placeholders
      #logger.info "####### results " + results.inspect
      end
    end
    return results
  end

  def state
    cr_state
  end

  def state=(value)
    self[:cr_state] = value
  end

  def save_remotely=(value)
    self[:saved_remotely] = value
  end

  def save_remotely?
    saved_remotely
  end

  def refresh!
    change_request = ServiceNow::Request.search(:value => "sys_id=#{sys_id}", :project_server_id => project_server_id)
    if change_request
      attrs = {}
      (Fields + TextAreaFields - [:cg_no, :cr_state] + [:number, :state]).each do |attr|
        if change_request.respond_to?(attr) && change_request.send(attr).is_a?(String)
          attrs[attr] = if attr == :state
            ProjectServer::ServiceNowStates[change_request.state]
          else
          change_request.send(attr)
          end
        end
      end
      # because type is a reserved word, we have to spoof this value as cr_type
      attrs[:cr_type] = change_request['type'] if change_request.respond_to?('type')
      set_attribute_values(attrs)
      update_attributes(attrs)
    end
  end

  def set_attribute_values(attrs)
    attrs[:u_application_name] = ServiceNowData.find_by_sys_id(attrs[:u_application]).try(:name) || attrs[:u_application] if attrs[:u_application].present?
    attrs[:u_cc_environment] = ServiceNowData.find_by_sys_id(attrs[:u_cc_environment]).try(:name) || attrs[:u_cc_environment] if attrs[:u_cc_environment].present?
    attrs[:assignment_group] = ServiceNowData.find_by_sys_id(attrs[:assignment_group]).try(:name) || attrs[:assignment_group] if attrs[:assignment_group].present?
    attrs[:u_pmo_project_id] = ServiceNowData.find_by_sys_id(attrs[:u_pmo_project_id]).try(:name) || attrs[:u_pmo_project_id] if attrs[:u_pmo_project_id].present?
    attrs
  end

  private

  def stringify_attributes!
    (Fields + TextAreaFields).each do |attr|
    #write_attribute(attr, nil) unless send(attr).is_a?(String)
    end
  end

end

