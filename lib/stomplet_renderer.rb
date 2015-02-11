class StompletRenderer
  def initialize
    @formats = [:json]
  end

  def each_format(model, properties)
    @formats.each do |format|
      response = send("render_#{format}", model, properties)
      yield(format, response) unless response.nil?
    end
  end

  def render_json(model, properties)
    model.to_json
  end
end