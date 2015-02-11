class GroupDecorator < ApplicationDecorator
  decorates :group

  delegate_all

  def link
    h.link_to object.name, h.edit_group_path(object)
  end

end
