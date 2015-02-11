class PermissionGranter

  class << self
    attr_reader :value_finders
  end

  def initialize(user = User.current_user)
    @user = user
  end

  def grant?(action, obj)
    raise NotImplementedError.new("Method grant should be implemented in child class #{self.class}.")
  end

  def self.set_key(key_)
    class_eval %{
      def key; "#{key_}".to_sym; end
    }
  end

  def self.value_for(subject, &block)
    @value_finders ||= {}
    @value_finders[subject.to_s] = block
  end

  def self.get_subject(obj)
    obj.is_a?(String) ? obj : obj.class.to_s
  end

  protected

  def get_values_for(obj, user = nil)
    value_finder = self.class.value_finders && self.class.value_finders[self.class.get_subject(obj)]
    Array( value_finder ? value_finder.call(obj, user) : obj.send("#{key}")).collect(&:to_i)
  end

  private

  def permission_map
    PermissionMap.instance
  end

end
