class RoleFormPage
  include Capybara::DSL

  def visit_page(id = nil)
    if id.nil?
      visit '/roles/new'
    else
      visit "/roles/#{id}/edit"
    end
  end

  def select_all_permissions
    find('.permissions > h3 .select-all').click
  end

  def clear_all_permissions
    find('.permissions > h3 .clear').click
  end

  def select_section(name)
    section_header(name).find(".select-all").click
  end

  def clear_section(name)
    section_header(name).find(".clear").click
  end

  def all_permissions
    all('.permissions input')
  end

  def section(name)
    return name unless name.kind_of? String
    first('label', text: name).find(:xpath, '../..')
  end

  def section_header(name)
    section(name).first('.header')
  end

  def section_content(name)
    section(name).first('ul')
  end

  def section_permissions(name)
    section(name).all('input')
  end

  def section_children_permissions(name)
    section_content(name).all('input')
  end

  def checkbox(name)
    label = first('label', text: name)
    find_by_id label[:for]
  end

  def toggle(name)
    section_header(name).click
  end
end