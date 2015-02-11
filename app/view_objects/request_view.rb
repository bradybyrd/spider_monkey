class RequestView
  def estimate
    List.get_list_items 'RequestEstimates', sort_by: proc{|key_value| key_value[1]} # sorted by value
  end
end