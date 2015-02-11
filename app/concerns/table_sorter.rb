module TableSorter
  def sort(records)
    records.reorder("#{sort_column} #{sort_direction}")
  end

  def sort_column
    if sort_column_is_safe?
      "#{sort_column_prefix}#{params[:sort]}"
    else
      "#{sort_column_prefix}name"
    end
  end

  def sort_column_is_safe?
    raise 'Implement `sort_column_is_safe?` method in your controller'
  end

  def sort_column_prefix
    ''
  end

  def sort_direction
    if %w[asc desc].include?(params[:direction])
      params[:direction]
    else
      'asc'
    end
  end
end
