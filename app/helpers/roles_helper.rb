module RolesHelper
  def permissions_tree(role, permissions)
    PermissionsTreeRenderer.new(role, self).render(permissions)
  end

  def permissions_toggle_tags(toggle_for = nil)
    content_tag :span, class: 'toggle-links' do
      concat content_tag(:a, 'Select All', href: '#', class: 'select-all', data: {for: toggle_for})
      concat ' | '
      concat content_tag(:a, 'Clear', href: '#', class: 'clear', data: {for: toggle_for})
    end
  end
end
