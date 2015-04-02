################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Activity < ActiveRecord::Base

  # TODO: RJ: Rails 3 - Log activities disabled due to plugin incompatibility for now
  #log_activities

  Roles   = List.get_list_items("Roles")

  Healths = List.get_list_items("Healths")

  ValidStatuses = List.get_list_items("ValidStatuses")
  ClosedStatuses = List.get_list_items("ClosedStatuses")
  ClosedConditions = "status IS NULL OR status NOT IN (#{ClosedStatuses.map{ |it| "'#{it}'" }.join(', ')})"

  DefaultAssociationColumns = {
    :manager => [:first_name, :last_name]
  }.with_indifferent_access

  belongs_to :user
  belongs_to :plan_stage
  belongs_to :activity_category
  belongs_to :current_phase, :class_name => "ActivityPhase"
  belongs_to :manager, :class_name => "User"
  belongs_to :leading_group, :class_name => "Group"

  has_many :uploads, :as => :owner, :dependent => :destroy

  # allow for uploads (a.k.a. assets) to be set through a nested form and updated without special
  # attribute accessors and prevalidation hooks.  This provides passthrough validatin messages to those forms.
  accepts_nested_attributes_for :uploads, :reject_if => lambda { |a| a[:attachment].blank? }, :allow_destroy => true

  has_many :workstreams, :dependent => :destroy
  has_many :resources, :through => :workstreams, :conditions => { :type => nil }
  has_many :placeholder_resources, :through => :workstreams, :source => :resource, :conditions => { :type => "PlaceholderResource" }

  has_many :activity_attribute_values, :dependent => :destroy
  has_many :activity_tabs, :through => :activity_category, :order => "#{ActivityTab.quoted_table_name}.position"
  has_many :activity_phases, :through => :activity_category, :order => "#{ActivityPhase.quoted_table_name}.position"
  has_many :deliverables, :class_name => "ActivityDeliverable", :dependent => :destroy do
    def on_phase(phase_id)
      self.all(:conditions => { :activity_phase_id => phase_id })
    end
  end
  # Don't worry!, :validate => false does NOT mean validations are skipped when the notes are saved.
  # It just means they are skipped when the Activity is saved. There are specs to verify that.
  # This is necessary because if notes/updates are built on a new record, they won't pass validation because their activity_id is nil.
  has_many :notes,   :class_name => "ActivityNote", :conditions => { :generic => true },  :validate => false, :dependent => :destroy
  has_many :updates, :class_name => "ActivityNote", :conditions => { :generic => false }, :validate => false, :dependent => :destroy

  has_many :index_columns, :through => :activity_category, :order => :position do
    def each
      self.all.each do |col|
        yield col.using(proxy_owner)
      end
    end
  end

  before_save :remove_workstreams_when_unallocatable, :unless => Proc.new { |a| a.projected_finish_at.nil? } # PP - Allerin
# commenting this before filter as per the rally defect #DE68083 - as shortcuts in create project form is the only custome attribute
# and we don't want to remove that attribute
  before_save :remove_custom_attrs, :if => Proc.new {|a| a.remove_custom_attr }
#  before_save :remove_custom_attrs
  #after_save :update_custom_attrs

  validates :name,
            :presence => true,
            :length => { :maximum => 255 }
  validates :activity_category_id,
            :presence => true
  validates :app,
            :presence => {:if => :should_have_app}

  validates :health,
            :inclusion => {:in => Healths, :allow_blank => true}

  #validates_uniqueness_of :name      # This is commented because when Plan created, Project gets created with same name.


  validate :deliverable_validations, :custom_attrs_validations

  # cf: some ugly conditions were added to this in case SYSTEM settings has an invalid value, not just nil, required for easy testing
  # FIXME: CF: Commenting out because it is throwing errors on save in raisl
  #validate :phase_start_date_validations, :on => :update
  #validates_format_of :planned_start_date, :with => Date::DATE_FORMATS[ GlobalSettings.connection.table_exists?(GlobalSettings.table_name) && !GlobalSettings[:default_date_format].nil? && GlobalSettings[:default_date_format].include?('%m') ? GlobalSettings[:default_date_format] : "%m/%d/%Y %I:%M %p" || "%m/%d/%Y %I:%M %p"], :allow_nil => true, :allow_blank => true

  #validates_format_of :planned_end_date, :with => Date::DATE_FORMATS[ GlobalSettings.connection.table_exists?(GlobalSettings.table_name) && !GlobalSettings[:default_date_format].nil? && GlobalSettings[:default_date_format].include?('%m') ? GlobalSettings[:default_date_format] : "%m/%d/%Y %I:%M %p" || "%m/%d/%Y %I:%M %p"], :allow_nil => true, :allow_blank => true

  #validates_format_of :last_phase_end_date, :with => Date::DATE_FORMATS[ GlobalSettings.connection.table_exists?(GlobalSettings.table_name) && !GlobalSettings[:default_date_format].nil? && GlobalSettings[:default_date_format].include?('%m') ? GlobalSettings[:default_date_format] : "%m/%d/%Y %I:%M %p" || "%m/%d/%Y %I:%M %p"],
  #  :allow_nil => true, :allow_blank =>  true

  attr_accessor :should_have_app, :last_phase_end_date, :planned_start_date, :planned_end_date, :remove_custom_attr
  attr_accessible :activity_category,:activity_category_id, :name, :leading_group_id, :status,
                  :planned_start, :planned_end, :projected_finish_at, :custom_attrs,:manager_id, :health,
                  :planned_end_date, :last_phase_end_date, :planned_start_date, :new_note, :uploads, :uploads_attributes,
                  :blockers, :theme, :phase_start_dates, :shortcuts

  # This dummy named scope is here for dashboard filtering.
  # TODO: Figure out a better way to handle this
  scope :active, all

  scope :request_compatible, joins(:activity_category).where("#{ActivityCategory.quoted_table_name}.request_compatible = ?", true).order("activities.name")

  scope :category_order, joins(:activity_category).order("activity_categories.name ASC")

  scope :roadmap_order, joins(:activity_category).order("activity_categories.name ASC, activities.name ASC")

  scope :name_order, order(:name)

  scope :with_placeholder_resources, lambda { includes(:placeholder_resources).where("#{Activity.quoted_table_name}.id = #{Workstream.quoted_table_name}.activity_id") }

  scope :allocatable, where(ClosedConditions)

#  named_scope :active_activities, { :conditions => ["status IS NULL OR status NOT IN (?)", ClosedStatuses.map{ |it| "'#{it}'" }.join(', ')] }
  scope :active_activities, where(ClosedConditions)

  scope :ongoing, where("LOWER(status)=?", 'ongoing')

  def self.available_for_user(user)
    unavailable_ids = Workstream.find_all_by_resource_id(user).map { |w| w.activity_id }
    if unavailable_ids.empty?
      self.all
    else
      where("#{Activity.quoted_table_name}.id NOT IN (?)", unavailable_ids)
    end
  end


  scope :in_group, lambda { |group| where(:leading_group_id => group ) }

  scope :no_group, lambda { where(:leading_group_id => nil) }

  scope :filtered_by_column, lambda { |column, value| where(column => value) }

#  named_scope :filter_by, proc { |filters_hash,role|
#    filters_hash = filters_hash.stringify_keys
#    opts = {}
#    if filters_hash.present?
#      opts[:conditions] = filters_hash
#    else
#      unless role
#        opts[:conditions] = ClosedConditions #"status NOT IN (#{ClosedStatuses.map{ |it| "'#{it}'" }.join(', ')})"
#      end
#    end
#    opts
#  }

  def self.with_projected_cost
    find_by_sql <<-SQL
      SELECT activities.*, b.p_cost AS projected_cost
      FROM activities
      LEFT OUTER JOIN
      ( SELECT activity_id, sum(projected_cost) as p_cost
        FROM budget_line_items
        GROUP BY activity_id
       ) b
      ON activities.id = b.activity_id
    SQL
  end

  def projected_cost
    # this will be nil unless you use the :with_cost named_scope
    self[:projected_cost]
  end

  def bottom_up_forecast
    # this will be nil unless you use the :with_cost named_scope
    self[:bottom_up_forecast]
  end

  def year_end_forecast
    # this will be nil unless you use the :with_cost named_scope
    self[:yef_2010]
  end

  def year_to_date_actual_spend
    # this will be nil unless you use the :with_cost named_scope
    self[:ytdas_2010]
  end

  def approved_spend
    # this will be nil unless you use the :with_cost named_scope
    self[:approved_spend]
  end

  scope :in_category, lambda { |cat| where(:activity_category_id => cat) }

  #serialize :theme,    Array
  #serialize :blockers, Array
  #serialize :phase_start_dates, Hash

  delegate :activity_attributes, :to => :activity_category
  delegate :creation_attributes, :to => :activity_category
  delegate :service?,            :to => :activity_category
  delegate :name, :to => :activity_category, :prefix => 'category'
  delegate :name, :to => :current_phase,     :prefix => true, :allow_nil => true
  delegate :name, :to => :manager,           :prefix => true, :allow_nil => true
  delegate :name, :to => :leading_group,     :prefix => true, :allow_nil => true


  # BJB 3/12/10 Optimize queryies for Oracle
  def self.fetch_by_group(cat_id, group, show_all, activity_ids=[], countonly=false, act=nil)
    if group == 0
      gs = 'IS null'
    else
      gs = '= ' + group.to_s
    end
    if show_all
      andclause = ""
    else
      andclause = "AND (#{ClosedConditions})"
    end
    if activity_ids.blank?
      ids = ""
    else
      conditions = ""
      activity_ids.each do |a|
        conditions += "#{a},"
      end
      ids = " AND activities.id IN (#{conditions[0,conditions.length-1]})"
    end
    if countonly
      conditions = "activity_category_id = #{cat_id} AND leading_group_id = #{group} #{andclause}"
      conditions += "AND name LIKE '%#{act}%'"  if act.present?
      act = find_by_sql <<-SQL
      SELECT count(*) as numrecords
      FROM activities
      WHERE #{conditions}
      SQL
      act[0].numrecords
    else
      find_by_sql <<-SQL
      SELECT activities.*, b.p_cost AS projected_cost
      FROM activities
      LEFT JOIN
      ( SELECT activity_id, sum(bottom_up_forecast) as p_cost
      FROM budget_line_items WHERE (budget_line_items.is_deleted = '0' OR budget_line_items.is_deleted IS NULL)
      AND budget_line_items.budget_year = '#{GlobalSettings[:budget_year]}'
      GROUP BY activity_id
      ) b
      ON activities.id = b.activity_id
      WHERE activity_category_id = #{cat_id} AND leading_group_id  #{gs} #{andclause} #{ids}
      ORDER BY name

      SQL
    end
  end


  def self.column_type(column)
    columns.find {|c| c.name == column }.class
  end

  def current_update
    updates.first(:order => 'created_at DESC').try(:contents)
  end


  def allocatable?
    status.nil? || ! ClosedStatuses.include?(status.titleize)
  end

  def start_on
    phase_start_date(activity_phase_ids.first) || created_at.to_date
  end

  def end_on
    last_phase_end_on || projected_finish_at.try(:to_date)
  end

  def phase_start_date phase
    return if phase_start_dates.value.blank?
    current_format = phase_start_dates[phase.to_param]
    unless (current_format =~ DATE_FORMATS.values[0]).nil?
      temp = current_format.present? ? current_format.split('/') : ""
      new_format = "#{temp[1]}/#{temp[0]}/#{temp[2]}"
    end

    date_str = new_format ? (new_format.to_date rescue nil) : (phase_start_dates[phase.to_param].to_date rescue nil)
  end

  def phase_end_date phase
    phase.last? ? last_phase_end_on : phase_start_date(phase.next)
  end

  def custom_attrs=(attrs_hash)
    @new_attrs_hash = attrs_hash
  end

  def health
    self[:health] || "green"
  end

  def new_note=(note_attrs)
    notes.build(note_attrs)
  end

  def new_update=(update_attrs)
    updates.build(update_attrs)
  end

  def shortcuts
    if shortcuts_attribute
      activity_attribute_values.where(activity_attribute_id: shortcuts_attribute.id).map(&:value).join(" ")
    end
  end

  def shortcuts=(shortcuts_text)
    activity_attribute_values.where(activity_attribute_id: shortcuts_attribute.id).destroy_all
    activity_attribute_values.create(activity_attribute_id: shortcuts_attribute.id, value: shortcuts_text)
  end

  def projected_finish
    projected_finish_at.to_s(:mdy)
  end

  def self.status_javascript
    # BJB Replace literals
    statusclause = "("
    ClosedStatuses.each do |status|
      statusclause += "($('#activity_status').val() == \"#{status}\")" + " || "
    end
    statusclause.chomp!(" || ")
    statusclause += ""
    return <<-JSEND
      function change_status()
      {
        if (#{statusclause}) && ($('#activity_last_phase_end_on').val() == ""))
        {
          alert("Missing Last Stage End Date: Terminating an activity requires an End on date.  Resource allocations after the End on date will be released.");
        }
      }
    JSEND
  end

  def activity_type_name
    # FIXME - Considered that Activity Type label will be as 'Activity Type'
    # TODO - Check with Rita from which part of App activity attribute values are created
    activity_attribute_values.find_by_activity_attribute_id(ActivityAttribute.find_by_name('Activity Type')).try(:value)
  end

  def is_closed?
    self.status.nil? ? false : !/terminate|complete|consolidate/.match(self.status.downcase).nil?
  end

  private

  def shortcuts_attribute
    activity_attributes.where(name: "Shortcuts").first
  end

  def custom_attrs_validations
    return unless @new_attrs_hash
    @new_attrs_hash.each do |attr_id, values|
      values = [values] unless values.is_a? Array
      values.each do |value|
        activity_attribute_value = activity_attribute_values.build(:activity_attribute_id => attr_id, :value => value, :new_activity => true)
        unless activity_attribute_value.valid?
          errors.add(:base,"#{activity_attribute_value.activity_attribute.name} #{activity_attribute_value.errors[:value]}")
        end
      end
    end
  end

  def update_custom_attrs
    return unless @new_attrs_hash
    #@new_attrs_hash.each do |attr_id, values|
    #  activity_attribute_values.find_all_by_activity_attribute_id(attr_id).map { |v| v.destroy }
    #end
    @new_attrs_hash.each do |attr_id, values|
      values = [values] unless values.is_a? Array
      #activity_attribute_values.find_all_by_activity_attribute_id(attr_id).map { |v| v.destroy }
      values.each do |value|
        activity_attribute_value = activity_attribute_values.create(:activity_attribute_id => attr_id, :value => value)
      end
    end
  end

  def remove_custom_attrs
    return unless @new_attrs_hash
    @new_attrs_hash.each do |attr_id, values|
      activity_attribute_values.find_all_by_activity_attribute_id(attr_id).map { |v| v.destroy }
    end
  end

  def phase_start_date_validations
    start_dates = activity_phases.map { |phase| phase_start_date(phase.id) }.compact
    start_dates << last_phase_end_on if last_phase_end_on
    start_dates.each_with_index do |date, idx|
      next if idx.zero?
      if date <= start_dates[idx - 1]
        errors.add(:base,"A stage cannot start on or before the start date of the previous stage")
        break
      end
    end

    phase_start_dates.each do |idx, date|
      date = date.to_date.strftime(GlobalSettings[:default_date_format].split[0]) if date =~ DATE_FORMATS.values[3]
      if !date.blank? && (date =~ DATE_FORMATS[GlobalSettings[:default_date_format]]).nil?
        errors.add(:base,"Estimated stage transitions date(s) has invalid format")
        break
      end
    end
  end

  def deliverable_validations
    deliverables.each do |d|
      validate_deliverable(d)
    end
  end

  def validate_deliverable(deliverable)
    phase = deliverable.activity_phase
    return if phase.nil?

    start_date = phase_start_date(phase)
    end_date = phase_end_date(phase)

    projected_date = deliverable.projected_delivery_on

    tag = "#{phase.name} / #{deliverable.name}"

    if start_date.nil? || end_date.nil?
      errors.add(:base,"Stages with deliverables must have start and end dates. [#{tag}]")
    elsif projected_date && (projected_date < start_date || projected_date >= end_date)
      errors.add(:base,"Stages with deliverables must contain the projected delivery date. [#{tag}]")
    end
  end

  def remove_workstreams_when_unallocatable
    if last_phase_end_date.present?
      if ClosedStatuses.include?(self.status.titleize)
        if GlobalSettings[:default_date_format] == "%m/%d/%Y %I:%M %p"
         end_date = last_phase_end_date.split('/')
         year = end_date[2]
         month = end_date[0]
        elsif GlobalSettings[:default_date_format] == "%d/%m/%Y %I:%M %p"
         end_date = last_phase_end_date.split('/')
         year = end_date[2]
         month = end_date[1]
        elsif GlobalSettings[:default_date_format] == "%Y/%m/%d %I:%M %p"
         end_date = last_phase_end_date.split('/')
         year = end_date[0]
         month = end_date[1]
        else
         end_date = last_phase_end_date.split('-')
         year = end_date[2]
         month = month_name_index(end_date[0])
        end
        collect_workstreams = Workstream.find(:all, :conditions => "activity_id = #{self.id}")
          collect_workstreams.each do |workstream|
            collect_allocations = ResourceAllocation.find(:all, :conditions => "allocated_id = #{workstream.id} AND allocated_type = 'Workstream' AND year >= #{year} AND month > #{month}")
            collect_allocations.each do |allocation|
              allocation.destroy
            end
          end
      end
    else
      errors.add(:base,"Please fill end date for #{self.status} status")
    end
  end

  def month_name_index(month_name)
    month = Date::ABBR_MONTHNAMES.index(month_name)
    return month
  end

  def self.import_app_request(xml_hash)
    if xml_hash["activity"]
      name = xml_hash["activity"]["name"]
      activity = find_by_name(name)
      if activity.present?
        activity.id
      end
    end
  end

end
