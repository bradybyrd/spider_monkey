class ListBuilder
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  LENGTH = {
    :"deployment_window/series" => 20,
    :"deployment_window/occurrence" => 100,
    :"user" => 50
  }

  attr_reader :subject, :options
  attr_accessor :visible, :list

  def initialize subject, options={}
    @subject = subject
    @options = options
    @visible = 0
    @list = []
    prepare_list
  end

  def display_list
    content = ''
    content << list.take(visible).join(', ').html_safe
    if list.length > visible
      content << omission
      content = content_tag :span do
        content.html_safe
      end
      content << content_tag(:span, list.join(', ').html_safe, class: 'hidden')
    end
    content.html_safe
  end

  private

    def prepare_list
      self.list = options[:only_names] ? build_names : build_links
    end

    def build_names
      names = subject.listable_props.sort_by { |name| name.length }
      calculate_visible names
      names
    end

    def build_links
      links = subject.linkable_props.sort_by{ |link| link[:name].length }
      calculate_visible links.map{ |l| l[:name] }
      user_apps = []
      user_root = subject.user.root?
      if !user_root
        user_apps = subject.user.apps
      end

      links.map do |link|
        has_apps = if user_root
                     link[:applications].any?
                   else
                     (link[:applications] & user_apps).any?
                   end

        if has_apps
          link_to(link[:name], 'javascript:void(0);', link[:html_attrs])
        else
          link[:name]
        end
      end
    end

    def calculate_visible(props)
      self.visible += 1
      props.inject do |memo, p|
        memo += (', ' + p)
        memo.length < LENGTH[subject.to_sym] ? self.visible += 1 : break
        memo
      end
    end

    def omission
      omission = ', ' + link_to("...(#{list.count - visible})", 'javascript:void(0);', class: 'more-links')
    end

end
