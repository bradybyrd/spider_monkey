class ListView
  def initialize(model_instance)
    @list = model_instance
  end

  def description
    if @list.is_text
      '* List accepts any string.'
    elsif @list.is_hash
      '* List accepts unique string as title and integer as a value.'
    else #list is numeric
      '* List accepts integers only.'
    end
  end
end