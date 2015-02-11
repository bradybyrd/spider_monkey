class GibberishHelper

  @cipher = Gibberish::AES.new('Secret key')

  class << self
    attr_reader :cipher
  end

  def self.decrypt_value(data, params)
    data = data.dup
    data = data.split('|')

    sub_params = get_sub_params(params, data)
    key = data[-2]
    sub_key = data[-1]

    if sub_params[key].has_key? sub_key
      value = sub_params[key][sub_key]
      sub_params[key][sub_key] = change_value(value, :dec) if value.present?
    end
  end

  def self.encrypt_value(value)
    return unless value.present?
    change_value(value, :enc)
  end

  private

  def self.change_value(value, method)
    if value.kind_of?(Array)
      value.flatten!
      value[0] = cipher.send method, value[0]
    else
      value = cipher.send method, value
    end
    value
  end

  def self.get_sub_params(params, data)
    sub_params = params
    data[0...-2].each do |key|
      sub_params = sub_params[key]
    end
    sub_params
  end
end