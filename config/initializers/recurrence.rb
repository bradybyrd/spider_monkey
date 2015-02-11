require 'ice_cube'

module IceCube
  class Rule
    def without(keys=[])
      rule_dup                  = self.dup
      validations_dup           = rule_dup.instance_variable_get(:@validations)
      unknown_keys              = Array(keys) - validations_dup.keys

      raise "No keys `#{unknown_keys}` for rule `#{self.inspect}`" unless unknown_keys.empty?

      validations_without_keys  = validations_dup.except(*keys)
      rule_dup.instance_variable_set :@validations, validations_without_keys

      rule_dup
    end
  end
end
