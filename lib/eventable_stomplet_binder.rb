class EventableStompletBinder
  include TorqueBox::Injectors if defined? TorqueBox::Injectors

  def initialize(attributes = [], renderer = nil)
    begin
      @destination = fetch('/topics/stomplets/event_bindable') if defined? TorqueBox::Injectors
      @attributes = attributes 
      @attributes = [@attributes] unless @attributes.is_a? Array
      @renderer = renderer || StompletRenderer.new
    rescue => e
      Rails.logger.error "#{e.inspect}"
    end  
  end

  def after_create(model)
    publish(model, :event => 'create')
  end

  def after_update(model)
    return true if (model.changed.size == 1 and model.changed.include?("updated_at"))
    publish(model, :event => 'update')
  end

  def after_destroy(model)
    publish(model, :event => 'destroy')
  end

  private

  def prepare_attributes(model)
    result = {
      :id => "#{model.id}",
      :model => model.class.to_s.downcase
    }
    @attributes.each do |name|
      res = model.try(name)
      result["#{name}"] = "#{res}" if res
    end
    result
  end

  def publish(model, properties)
    return true unless @destination
    begin
      properties = properties.merge(prepare_attributes(model))
      @renderer.each_format(model, properties) do |format, response|
        properties = properties.merge({:format => format})
        @destination.publish(response, :properties => properties)
        Rails.logger.info "Published message with prioperties: #{properties.inspect}, model.changed: #{model.changed}"
      end
    rescue => e
      Rails.logger.error "#{e.inspect}"
    end
    true
  end
end
