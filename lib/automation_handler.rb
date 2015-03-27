class AutomationHandler < TorqueBox::Messaging::MessageProcessor
  def on_message(body)
    # The body will be of whatever type was published by the Producer
    # the entire JMS message is available as a member variable called message()

    if body.is_a? Hash
      body[:args] ||= []
      raise ArgumentError, 'Method not specified'    unless body.include? :method
      raise ArgumentError, 'Object not specified'    unless body.include? :object

      @options  = body[:options] if body[:options]
      @object   = body[:object]

      @object.send(body[:method], *body[:args])
    end
  end

  def on_error(error)
    if @options[:error_handler_method]
      args = @options[:args] || []
      args << error_message(error)
      @object.send(@options[:error_handler_method], *args)
    else
      raise "#{error_message(error)}"
    end
  end

  def error_message(error)
    if error.respond_to?(:backtrace)
      error.backtrace
    else
      error.inspect
    end
  end
end