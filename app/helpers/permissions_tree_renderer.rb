class PermissionsTreeRenderer
  attr_reader :role

  def initialize(role, template)
    @role = role
    @template = template
  end

  def render(permissions, nested = false)
    content_tag :ul do
      permissions.each do |permission|
        concat render_permission(permission, nested)
      end
    end
  end

  def render_permission(permission, nested)
    permission_section = PermissionSection.new(permission, nested)
    content_tag :li, id: "list_#{permission_section.id}", class: permission_section.css_classes, data: permission_section.data do
      concat (content_tag :div, class: 'header' do
        concat render_expand_tag unless nested

        if !permission['id'].blank? || nested
          concat check_box_tag(permission_section.input_name, permission['id'], role.permission_ids.include?(permission['id'].to_i),
                               id: permission_section.input_id)
        end
        concat label_tag(permission_section.input_id, permission['name'])
        concat permissions_toggle_tags if !nested && permission_section.show_toggle?
      end)
      concat self.render(permission_section.children, true) if permission_section.has_children?
    end
  end

  def render_expand_tag
    content_tag :span, '', class: 'expand'
  end

  def method_missing(*args, &block)
    @template.send(*args, &block)
  end

  private

  class PermissionSection
    attr_reader :permission, :nested

    def initialize(permission, nested)
      @permission = permission
      @nested = nested
    end

    def css_classes
      classes = ''
      classes << ' collapsed top-section' unless nested
      classes << ' folder' if permission['id'].blank?
      classes << " depends depends#{permission['depends_on_id']}" unless permission['depends_on_id'].blank?
      classes
    end

    def data
      data = {}
      data[:depends_on] = permission['depends_on_id'] unless permission['depends_on_id'].blank?
      data
    end

    def id
      permission['id'] || permission.object_id
    end

    def input_id
      "permission#{id}"
    end

    def input_name
      permission['id'].blank? ? "" : "role[permission_ids][]"
    end

    def children
      permission['items'].blank? ? [] : permission['items']
    end

    def show_toggle?
      has_children? && (children.size > 1 || PermissionSection.new(children[0], nested).has_children?)
    end

    def has_children?
      !children.blank?
    end
  end
end