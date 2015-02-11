module PackageSortingAndPaginationHelper
  def pagination_links
    find('.pagination')
  end

  def have_current_page(page_number)
    have_css('em.current', text: page_number)
  end

  def have_link_to_page(page_number)
    have_css('a', text: page_number)
  end

  def list_first(package)
    have_css('tr:first-child', text: package.name)
  end

  def list_last(package)
    have_css('tr:last-child', text: package.name)
  end

  def toggle_sort_direction
    find('#active_table').click_on('Name')
  end

  def click_second_page
    find('.pagination').click_on('2')
  end
end
