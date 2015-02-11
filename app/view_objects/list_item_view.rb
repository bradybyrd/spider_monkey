class ListItemView
  def initialize(model_instance)
    @list_item = model_instance
  end

  def value_hash
    "#{@list_item.value_text}:#{@list_item.value_num}"
  end
end