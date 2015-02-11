class ApplicationDecorator < Draper::Decorator
  NUMBER_OF_LINKS_TO_SHOW = 5
  SHOW_MORE_LINK_CLASS = 'show_more_expandable_links'
  VISIBLE_EXPANDABLE_LINKS_CLASS = 'visible_expandable_links'
  HIDDEN_EXPANDABLE_LINKS_CLASS = 'hidden_expandable_links'

  def association_expandable_links(links) #may be this should go to ApplicationHelper but I afraid ApplicationHelper here. May be I'll extract it to a gem
    visible_links = links[0...NUMBER_OF_LINKS_TO_SHOW]
    hidden_links = links[NUMBER_OF_LINKS_TO_SHOW..-1]
    link_tags = visible_association_expandable_links(visible_links)
    unless hidden_links.blank?
      link_tags << hidden_association_expandable_links(hidden_links)
    end
    link_tags
  end

  private

  def visible_association_expandable_links(links)
    h.content_tag(:span, links.join(', ').html_safe, class: 'visible_expandable_links')
  end

  def hidden_association_expandable_links(links)
    content = ' '
    content << h.link_to("... (#{ links.count })", 'javascript:void(0);', class: SHOW_MORE_LINK_CLASS)
    content << h.content_tag(:span, class: HIDDEN_EXPANDABLE_LINKS_CLASS, style: 'display: none;') do
      ', '.concat(links.join(', ')).html_safe
    end
    content.html_safe
  end

end
