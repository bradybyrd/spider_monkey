################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityDeliverable < ActiveRecord::Base
  
  include CalendarInstanceMethods
  
  SortScope = [ :leading_group_id, :deployment_contact_id, :organizational_impact, :delivered ]
  
  belongs_to :activity
  belongs_to :activity_phase
  belongs_to :deployment_contact, :class_name => "User", :foreign_key => "deployment_contact_id"
  
  has_many :activity_attribute_values, :class_name => 'ActivityAttributeValue', :as => :value_object

  validates :name,
            :presence => true
  validates :activity_id,
            :presence => true
  validates :projected_delivery_on,
            :presence => {:if => Proc.new { |ad| ad.release_deployment }}
  validates :deployment_contact_id,
            :presence => {:if => Proc.new { |ad| ad.release_deployment }}
  validate :validate_projected_delivery_on, :phase_has_start_and_end, :custom_attrs_validations
  
  scope :release_deployment, where(:release_deployment => true)
  
  attr_accessor :projected_delivery_date, :delivered_date
  
  before_save :delete_custom_attrs
  after_save  :save_custom_attrs
  
  def self.between_dates(start_date, end_date)
    start_date = start_date.nil_or_empty? ? ActivityDeliverable.first_deliverable_date  : start_date.to_time.beginning_of_day.in_time_zone
    end_date = end_date.nil_or_empty? ?  (Time.now + 10.years).in_time_zone : end_date.to_time.end_of_day.in_time_zone
    coalesce_sql = 'COALESCE(activity_deliverables.projected_delivery_on, activity_deliverables.delivered_on)'
    select("activity_deliverables.*, #{coalesce_sql} AS order_column").
    where("#{coalesce_sql} BETWEEN ? AND ?", start_date, end_date).
    order(coalesce_sql)
  end
  
  scope :with_leading_group_id, lambda {|leading_group_id| includes(:activity).where("activities.leading_group_id" => leading_group_id) }
  
  scope :with_deployment_contact_id, lambda { |deployment_contact_id| where(:deployment_contact_id => deployment_contact_id) }
  
  scope :delivered, where("activity_deliverables.delivered_on IS NOT NULL ")
  
  scope :not_delivered, where("activity_deliverables.projected_delivery_on IS NOT NULL ")
  
  scope :with_organizational_impact, lambda { |organizational_impact_ids| includes(:activity_attribute_values).
        where("activity_attribute_values.id" => organizational_impact_ids) }
  
  def validate
    if !projected_delivery_date.blank? && (projected_delivery_date =~ DATE_FORMATS[GlobalSettings[:default_date_format]]).nil?
      errors.add(:projected_delivery_on, "has invalid format")
    end
    if !delivered_date.blank? && (delivered_date =~ DATE_FORMATS[GlobalSettings[:default_date_format]]).nil?
      errors.add(:delivered_on, "has invalid format")
    end
  end
  
  class << self
    
    def all_organizational_impact
      ActivityDeliverable.release_deployment.map(&:activity_attribute_values).flatten.select {|aav| !aav.value.nil?}.sort_by(&:value)
    end
    
    def organizational_impact
      ActivityAttribute.find 827 rescue nil
    end
    
    def delivered_filters_for_select
      (["delivered", "not_delivered", "all"].collect { |status| [status.humanize, status] })
    end
    
    def first_deliverable_date
      first_deliverable = ActivityDeliverable.first
      first_deliverable.nil? ? Time.now.in_time_zone : first_deliverable.created_at.in_time_zone 
    end
    
    def filtered(filters)
      deliverables = self
      if filters
        
        %w(leading_group_id deployment_contact_id).each do |attr|
          deliverables = deliverables.send("with_#{attr}", filters[attr]) unless filters[attr].blank?
        end
        
        if filters["delivered"].present?
          if filters["delivered"] == ["delivered"] or filters["delivered"] == ["not_delivered"]
            deliverables = deliverables.send(filters["delivered"].first)
          end
        end
        
        if filters["organizational_impact"].present?
          deliverables = deliverables.with_organizational_impact(filters["organizational_impact"])
        end
        
      end
      deliverables.scoped({})
    end
    
  end
  
  def custom_attrs_array
    activity_attribute_values.map(&:value).uniq
  end
  
  def organization_impact_values
    custom_attrs_array.join(', ')
  end
  
  def delivery_highlights; description end
  
  def custom_attrs=(attrs_hash)
    @new_attrs_hash = attrs_hash
  end
  
  def save_custom_attrs
    return unless @new_attrs_hash
    @new_attrs_hash.each do |attr_id, values|
      values = [values] unless values.is_a? Array
      values.flatten.uniq.each do |value|
       activity_attribute_values.create(:activity_attribute_id => attr_id, :value => value)
      end
    end
  end

  def delete_custom_attrs
    return unless @new_attrs_hash
    @new_attrs_hash.each do |attr_id, values|
      activity_attribute_values.find(:all, :conditions => { :activity_attribute_id => attr_id.to_i }).each { |aav| aav.destroy }
    end
  end
  
  def calendar_time_source
    [:delivered_on, :projected_delivery_on].detect do |attr|
      send(attr).present?
    end
  end
  
  # Color Codes for Deliverable
  # Delivered - Green
  # Not Delivered but Projected Delivery is in future - Grey
  # Not Delivered but Projected Delivery is in past - Orange
  
  def css_klass
    if is_delivered?
      "deliverableDelivered"
    else
      if projected_delivery_on.nil?
        "deliverablePlanned"
      elsif projected_delivery_is_in_future?
        "deliverableIsinFuture"
      else
        "deliverableIsInPast"
      end
    end
  end
  
  def is_delivered?
    !delivered_on.nil?
  end
  
  def projected_delivery_is_in_future?
    projected_delivery_on > Date.today
  end
  
  private

  def phase_start_date
    activity.try(:phase_start_date, activity_phase)
  end

  def phase_end_date
    activity.try(:phase_end_date, activity_phase)
  end

  def validate_projected_delivery_on
    return unless activity && activity_phase && projected_delivery_on

    if projected_delivery_on < phase_start_date || projected_delivery_on >= phase_end_date
      errors.add(:projected_delivery_on, 
                 "must be within the lifespan of the stage (from #{phase_start_date.to_s(:simple)} to #{phase_end_date.to_s(:simple)})")
    end
  end

  def phase_has_start_and_end
    return unless activity_phase

    unless phase_start_date && phase_end_date
      self.errors[:base] << "A deliverable cannot be added to a stage without both a start and end."
    end
  end
  
  def custom_attrs_validations
    return unless @new_attrs_hash
    @new_attrs_hash.each do |attr_id, values|
      values = [values] unless values.is_a? Array
      values.each do |value|
        activity_attribute_value = activity_attribute_values.build(:activity_attribute_id => attr_id, :value => value, :new_activity => true)
        unless activity_attribute_value.valid?
          self.errors[:base] << "#{activity_attribute_value.activity_attribute.name} #{activity_attribute_value.errors.on(:value)}"
        end
      end
    end
  end
  
end
