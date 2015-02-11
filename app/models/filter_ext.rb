module FilterExt

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

=begin

Usage:

  is_filtered cumulative: [:first_name, :last_name, :email],
    cumulative_by: {keyword: :by_keyword, is_root: :root,  key: :by_key},
    boolean_flags: {default: :active, opposite: :inactive},
    default_flag: :all (or default_flag: :active )
    specific_filter: :user_specific_filters
* boolean_flags or default_flag should be present but not both of them

  def self.user_specific_filters(entities, adapter_column, filters = {})
    if (adapter_column.value_to_boolean(filters[:root]))
      entities.root_users
    else
      entities
    end
  end

=end

    def is_filtered(options = {})
      cumulative = options[:cumulative] || []
      cumulative_by = options[:cumulative_by] || {}
      specific_filter = options[:specific_filter]
      boolean_flags = options[:boolean_flags]
      default_flag = options[:default_flag]

      is_boolean_flags = boolean_flags.present?
      is_default_flag = default_flag.present?

      if (is_boolean_flags and (not is_default_flag)) or ((not is_boolean_flags) and is_default_flag)
        if is_boolean_flags
          active_name = boolean_flags[:default]
          inactive_name = boolean_flags[:opposite]
        end
      else
        if is_boolean_flags and is_default_flag
          raise 'Only one of boolean_flags or default_flag should be present, but not both of it'
        else
          raise 'One of boolean_flags or default_flag should be present, no one is present'
        end
      end

      define_singleton_method(:filtered) do |filters = {}|
        filters ||= {}

        if is_default_flag
          if default_flag == :all
            entities = self.scoped
          else
            entities = self.send default_flag
          end
        end

        # borrow the active record truthiness function to handle varied user input
        adapter_column = ActiveRecord::ConnectionAdapters::Column

        unless filters.blank?

          if !is_default_flag
            entities = self

            # always work with the active group unless active = false is added to the filter
            inactive_flag        = adapter_column.value_to_boolean(filters[inactive_name])
            active_flag          = adapter_column.value_to_boolean(filters[active_name])

            if inactive_flag and active_flag
              # self.all as a scope
              entities = entities.scoped
            elsif inactive_flag
              entities = entities.send inactive_name
            elsif active_flag || filters[active_name].blank?
              entities = entities.send active_name
            else # active and inactive == false
              return []
            end
          end

          # add the cumulative filters as needed
          cumulative.each do | filter |
            unless filters[filter].blank?
              if entities.respond_to?("filter_by_#{filter}")
                entities = entities.send "filter_by_#{filter}", filters[filter]
              else
                entities = entities.where(filter => filters[filter])
              end
            end
          end

          cumulative_by.each do | filter, method |
            unless filters[filter].blank?
              if entities.respond_to?(method)
                entities = entities.send method, filters[filter]
              else
                raise "Method: [#{method}] with arg: [#{filters[filter]}] not applicable for [#{self}]"
              end
            end
          end
        else
          if !is_default_flag
            entities = self.send active_name
          end
        end
        entities = entities.send specific_filter, entities, adapter_column, filters unless specific_filter.blank?
        # check for safety in case bare class made it through filters
        return entities
      end
    end
  end
end