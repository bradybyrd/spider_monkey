module AssociationFreezer
  class BelongsToFreezer
    def initialize(owner, reflection)
      @owner = owner
      @reflection = reflection
    end
    
    def freeze
      self.frozen_data = Marshal.dump(nonfrozen.attributes) if nonfrozen
    end
    
    def unfreeze
      @frozen = nil
      self.frozen_data = nil
    end
    
    def fetch(*args)
      frozen || nonfrozen(*args)
    end
    
    def frozen?
      frozen_data
    end
    
    private
    
    def frozen
      @frozen ||= load_frozen if frozen?
    end
    
    def load_frozen
      begin
        attributes = Marshal.load(frozen_data)
      rescue => e
        # TODO This is a temporary commit to help with debugging tests
        raise TypeError.new("Failed to unmarshal `#{frozen_data}` because of error: #{e.inspect}")
      end

      protected_attrs = ['id']
      protected_attrs += target_class.protected_attributes.to_a if target_class.protected_attributes
      protected_attrs += attributes.keys - target_class.accessible_attributes.to_a if target_class.accessible_attributes

      #### 2013-01-14, gkathare, had to patch to fix issue with encoding. ####
      frozen_attrs = attributes.except(*protected_attrs)
      if OracleAdapter
        frozen_attrs.each do |attr|
          if attr[1].is_a?(String) && attr[1].encoding.name == "ASCII-8BIT"
            frozen_attrs[attr[0]] = attr[1].force_encoding("utf-8")
          end
        end
      end

      target = target_class.new(frozen_attrs)
      protected_attrs.each do |attr|
        target.send("#{attr}=", attributes[attr]) if target.respond_to?("#{attr}=")
      end

      target.instance_variable_set('@new_record', false)
      target.readonly!
      target.freeze
    end
    
    def nonfrozen(*args)
      @owner.send("#{name}_without_frozen_check", *args)
    end
    
    def frozen_data=(data)
      @owner["frozen_#{name}"] = data
    end
    
    def frozen_data
      @owner["frozen_#{name}"]
    end
    
    def target_class
      if @reflection.options[:polymorphic]
        @owner.send("#{name}_type").constantize
      else
        @reflection.klass
      end
    end
    
    def name
      @reflection.name
    end
  end
end
