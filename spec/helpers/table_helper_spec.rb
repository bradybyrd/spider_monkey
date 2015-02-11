require 'spec_helper'

describe TableHelper do
  describe 'sortable_link' do
    it 'returns a link with the title and the sort column' do
      resource_is_sorted_by('column_to_sort')

      generate_sortable_link('My Title', 'column_to_sort')

      expect(helper).to have_created_link(
        title: 'My Title', column: 'column_to_sort', html_class: 'headerSortDown'
      )
    end

    it 'links to desc direction if already sorted by that column in asc' do
      resource_is_sorted_by('column_to_sort', 'asc')

      generate_sortable_link('My Link', 'column_to_sort')

      expect(helper).to have_created_link(
        column: 'column_to_sort', direction: 'desc', html_class: 'headerSortDown'
      )
    end

    it 'links to asc direction and corresponding class if already sorted by that column in desc' do
      resource_is_sorted_by('column_to_sort', 'desc')

      generate_sortable_link('My Link', 'column_to_sort')

      expect(helper).to have_created_link(
        column: 'column_to_sort', direction: 'asc', html_class: 'headerSortUp'
      )
    end

    it 'links to ascending direction and has no class if not sorting by that column' do
      resource_is_sorted_by('column_being_sorted', 'asc')

      generate_sortable_link('My Link', 'different_column')

      expect(helper).to have_created_link(
        column: 'different_column', direction: 'asc', html_class: ''
      )
    end
  end

  def resource_is_sorted_by(column, direction = 'asc')
    allow(helper).to receive(:sort_direction).and_return(direction)
    allow(helper).to receive(:sort_column).and_return(column)
    allow(helper).to receive(:link_to)
  end

  def generate_sortable_link(title, column_to_sort)
    helper.sortable_link(title, column_to_sort)
  end

  def have_created_link(options = {})
    options = options.reverse_merge(default_link_options)
    have_received(:link_to).with(
      options[:title],
      { sort: options[:column], direction: options[:direction] },
      { class: "#{options[:html_class]} sortable-link"}
    )
  end

  def default_link_options
    { title: anything(), column: anything(), direction: 'desc', html_class: '' }
  end
end
