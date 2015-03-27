################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ObjectState

  WARNING_STATES = {
      draft: "It is available only to you.",
      pending: "It is not yet released - use with caution.",
      retired: "It is not recommended for use."
  }

  STATE_TRANS_TO_STATE = {
      make_private: "draft",
      begin_testing: "pending",
      release: "released",
      retire: "retired" ,
      archival: "archived",
      reopen: "pending"
  }

  def self.included(base)
    base.extend ObjectState::ClassMethods
    base.send :include, ObjectState::InstanceMethods
  end

  module ClassMethods

    def init_state_machine
      include AASM

      attr_accessor :is_import
      belongs_to :creator, class_name: 'User', foreign_key: :created_by

      scope :visible, lambda { |obj_type=""| 
        where("(#{obj_type == "" ? "":obj_type + '.'}aasm_state <> 'draft') ")
      }
      scope :visible_in_index, lambda { |obj_type=""|
        where("(#{obj_type == "" ? "":obj_type + '.'}aasm_state <> 'draft')
              OR (#{obj_type == "" ? "":obj_type + '.'}aasm_state = 'draft'
                AND (#{obj_type == "" ? "":obj_type + '.'}created_by = #{User.current_user.id}))") unless User.current_user.admin? 
      }
      scope :not_draft, lambda { |obj_type=""| where("(#{obj_type == "" ? "":obj_type + '.'}aasm_state <> 'draft')")}

      aasm create_scopes: false do
        state :draft, initial: true
        state :pending
        state :released
        state :retired
        state :archived_state

        event :make_private do
          transitions to: :draft, from: [:pending]
        end

        event :begin_testing do
          transitions to: :pending, from: [:draft, :released]
        end

        event :release do
          transitions to: :released, from: [:pending, :retired]
        end

        event :retire, success: :in_use_warning do
          transitions to: :retired, from: :archived_state, after: :unarchive_item
          transitions to: :retired, from: :released
        end

        event :archival, success: :archive_item do
          transitions to: :archived_state, from: [:retired], guard: :can_be_archived?
        end

        event :reopen do
          transitions to: :pending, from: [:retired, :archived_state]
        end

        event :archival_no_archive do
          transitions to: :archived_state, from: [:retired]
        end

      end
      
      validates :aasm_state, inclusion: { in: aasm.states.map(&:name).map(&:to_s) + ['archived'],
        message: "%{value} is not included in #{(aasm.states.map(&:name) + ['archived']).to_sentence(last_word_connector: ' or ')}" }
      validates_with DraftStateCreateValidator
    end
  end


  module InstanceMethods
    def event_transitions
      ["make_private", "begin_testing", "release", "retire", "archival", "reopen"]
    end

    def state_descriptions
      result = {}
      cur_states = self.class.aasm.states.map(&:name)
      descs = { draft: "Draft is only visible to the author",
                pending: "Pending can be used with a warning",
                released: "Released are for general use",
                retired: "Retired can be used with a warning",
                archived_state: "Archived are not visible" }
      cur_states.each do |state|
        result[state] = descs[state] if descs.has_key?(state)
        result[state] = state unless descs.has_key?(state)
      end
      result
    end

    def state_info
      info = {}
      cur_state = self.aasm_state
      if cur_state.nil?
        cur_state = "draft"
        self.aasm_state = cur_state
        self.save(validation: false)
      end
      info["states"] = state_descriptions
      #logger.info "SS__ state_info: #{state_descriptions}"
      ipos = info["states"].keys.index(cur_state.to_sym)
      info["previous_state_transition"] = event_transitions[ipos - 1] if ipos - 1 >= 0
      info["next_state_transition"] = event_transitions[ipos + 1] if ipos + 1 < event_transitions.size

      STATE_TRANS_TO_STATE.each do |key, value|
        if  key.to_s.eql? info["previous_state_transition"]
         info["previous_state"] = value
        elsif key.to_s.eql?  info["next_state_transition"]
         info["next_state"] = value
        end
      end
      if cur_state == 'archived_state'
         info["next_state"] = ''
      end
      # Don't allow archived_state state if not archivable
      if (info["next_state"] == 'archived_state' || info["next_state"] == 'archived') && !self.can_be_archived?
        info["next_state"] = ''
        info.delete(:next_state_transition)
        info["states"].delete(:archived_state)
      end
       info
    end

    def warning_state?
      WARNING_STATES.keys.include?(aasm_state.to_sym)
    end

    def warning_state
      obj_name = self.class.to_s.underscore.humanize.downcase
      obj_name = obj_name.gsub('/',' ')
      "Warning, the #{obj_name} being used is in a #{aasm_state.upcase} state.  #{WARNING_STATES[aasm_state.to_sym]}"
    end

      # placeholder for warning stuff about impact of retiring
    def in_use_warning
      return true
    end

    def archive_item
      logger.info "SS__ Archiving"
      toggle_archive
      return true
    end

    def unarchive_item
      logger.info "SS__ UnArchiving"
      toggle_archive
      return true
    end

    def can_change_aasm_state?
      User.current_user.admin? || created_by == User.current_user.id || aasm_state != 'draft'
    end

    def can_view_draft?
      User.current_user.admin? || created_by == User.current_user.id
    end

    def draft?
      aasm_state == 'draft'
    end

    def transition_using_state(state)
      if transition = STATE_TRANS_TO_STATE.key(state)
        begin
          self.send("#{transition}!")
        rescue => err
          self.errors.add(:aasm_state, err.message)
          false
        end
      else
        update_attributes(aasm_state: state)
      end
    end

    def update_attributes_with_state(params)
      if new_state = params.delete(:aasm_state)
        ActiveRecord::Base.transaction do
          update_with_state(params, new_state)
        end
      else
        update_attributes(params)
      end
    end

    def update_with_state(params, new_state)
      if archived?
        success = transition_using_state(new_state)
        update_attributes(params) if success
      elsif new_state.include?('archived')
        success = update_attributes(params)
        transition_using_state('archived') if success
      else
        update_attributes(params.merge(aasm_state: new_state))
      end
    end
  end
end
