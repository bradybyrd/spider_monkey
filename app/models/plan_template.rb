################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanTemplate < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt
  include ObjectState

  concerned_with :plan_template_named_scopes

  # also prevent destruction if there are linked plans who need
  # the template for their stage information

  attr_accessible :name, :template_type, :is_automatic, :aasm_state


  normalize_attributes :name
  TYPES = [
          ['Continuous Integration', 'continuous_integration'],
          ['Deploy', 'deploy'],
          ['Release Plan', 'release_plan']
          ]

  STATES = %w(created planned started locked complete deleted archived hold cancelled)

  has_many :stages, :class_name => 'PlanStage', :order => 'plan_stages.position', :dependent => :destroy
  has_many :plans, :dependent => :destroy

  scope :name_order, order(:name)

  scope :having_template_types, lambda { |template_types|  where(:template_type => template_types).order(:name) }

  validates :name, :presence => true
  validates :name, :length => { :maximum => 255 }
  validates :name, :uniqueness => { :case_sensitive => false }
  validates :template_type, :inclusion => { :in => TYPES.map { |t| t[1] },
    :message => "%{value} is not included in #{TYPES.map { |t| t[1] }.to_sentence}" }


  # initialize AASM state machine for object status
  init_state_machine

  def default_stage_id
    stage_ids.first
  end

  def template_type_label
    my_label = ''
    unless self.template_type.nil?
      # grab the array for the matching template_type
      matching_types = TYPES.select { |t| t[1] == self.template_type } || []
      unless matching_types.empty?
        # if a match was found, return the label element of the first match
        my_value = matching_types[0]
        my_label = my_value[0] unless my_value.nil? || my_value.try(:length) < 1
      else
        my_label = "Unsupported type: #{self.template_type}"
      end
    end
    return my_label
  end

  def to_label
    my_label = []
    my_label << self.name unless self.name.blank?
    my_label << self.template_type_label unless self.template_type.blank?
    return my_label.join(" - ")
  end

 # plan templates have stages and plans, but stages need not be archived as they have no index listing
  # and lifecyles need to just restrict archiving if they are active.  Otherwise, we can deactive a template
  # without worrying too much about plans with those archived templates -- they cannot pick a new template
  # from any select box and therefore the association will just sit there.
  # plan templates support plans by providing their stage information. Once created,
  # a plan cannot change its type and therefore there are no forms allowing the reselection
  # of plan templates for existing plans.  Nonetheless, we should restrict archiving
  # of plan templates for all running plans (not archived, deleted, or cancelled)
  # to be sure that currently working plans have an easy to find plan template.

  # returns a boolean to the before_archive hook and any view
  # that needs to decide to show or hide the archive link
  def can_be_archived?
    return self.plans.running.count == 0
  end

end
