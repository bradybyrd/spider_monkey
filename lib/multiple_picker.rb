module MultiplePicker
  OPTIONS = {
      :object => '', # parent object for wich multiple picker should select items
      :object_scope => '', # name of scope or scope proc for getting selected items :TBD
      :object_item_relation => '', # name of relation from object to items by default is used from item_class
      :object_class => 'required', # underscorizable class of object to be used when set value
      :item_class => 'required', # class of Model of items that should be selected in multiple picker
      :items_scope => '', # name of scope or scope proc for getting all items :TBD
      :item_display_field => 'required',
      :auto_submit => '', # if true will auto submit the form on the main page
      :form_name => '',   # if set, this will be the form to submit
    }

  class ItemsSelect
    attr_reader :params, :selected_items, :items, :user

    def initialize params, user
      @params = params
      @user = user
      @items = []
      @selected_items = []
      prepare_items
    end

    def select_items
      [items, selected_items]
    end


    private

      def prepare_items
        get_selected_items
        get_items
      end

      def items_primary_key
        @keys ||= items_model.primary_key
      end

      def items_model
        @model ||= params[:item_class].camelize.constantize
      end

      def items_columns
        @columns ||= [items_primary_key, params[:item_display_field]]
      end

      def filters
        params[:filters]
      end

      def relation
        params[:item_class].pluralize
      end

      def get_selected_items
        if params[:id].blank?
          @selected_items = params[:relation_ids] || []
          @selected_items = @selected_items.map{|el| [el, items_model.find(el).send(params[:item_display_field])]}
        else
          object = params[:object].camelize.constantize.find(params[:id])
          @selected_items = object.send(relation).map{|el| [el.send(items_primary_key), el.send(params[:item_display_field])]}
        end
      end


      def get_items
        if @selected_items.empty?
          @items = items_model.active.
            select(items_columns).
            where(filters)
        else
          @items = items_model.active.scoped.extending(QueryHelper::WhereIn).
            select(items_columns).
            where(filters).
            where_not_in(items_primary_key, @selected_items.map{|el| el.first})
        end

        if params[:controller] == "deployment_window/series"
          @items = @items.select{ |env| user.environments.include? env }
        end
        map_items
      end

      def map_items
        @items = @items.map{|el| [el.send(items_primary_key), el.send(params[:item_display_field])]}
      end

  end

  def show_picker
      raise "Params #{OPTIONS.reject{|k,v| v != 'required'}.keys.join(', ')} are required!!!" unless OPTIONS.reject{|k,v| v != 'required'}.keys.select{|k| params[k].blank?}.empty?

      items, selected_items = ItemsSelect.new(params, current_user).select_items
      required_params_hash = Hash[OPTIONS.reject{|k,v| v != 'required'}.collect{|pair| [pair[0], params[pair[0]]]}]
      render( partial: 'shared/multiple_picker',
              locals: {
                items: items,
                selected_items: selected_items,
                item_display_field: params[:item_display_field],
                auto_submit: params[:auto_submit],
                form_name: params[:form_name]
              }.merge(required_params_hash),
              :layout => false)
  end

  module Helper

    LINK_ID_PREFIX = "show_picker_link_for_"

    def link_to_multiple_picker(item_class, options = {})
      raise "Param object is required!!!" unless options[:object]

      object = options.delete(:object)
      options[:object] = object.class.to_s

      rel_ids = item_class.to_s << '_ids'

      options[:relation_ids] = object.try(:"#{rel_ids}")

      add_index = object.id.blank? && item_class == :environment
      path = "show_picker_#{object.class.to_s.pluralize.underscore.gsub('/', '_')}_#{'index_' if add_index}url"
      hash = {:item_class => item_class.to_s, :object_class => object.class.to_s.gsub('::', '')}.merge(options).merge({:id => object.id}.reject{|k,v| v.blank?})
      path = self.send(path, hash)

      if object.send(rel_ids).blank?
        text = "Add  #{item_class.to_s.capitalize}"
        link_to(text, path, remote: true, rel: 'facebox', id: "#{LINK_ID_PREFIX}#{item_class.to_s.downcase}_id")
      else
        text = "Change #{item_class.to_s.capitalize} (selected #{object.send(rel_ids).count})"
        link_to(text, path, remote: true, rel: 'facebox', id: "#{LINK_ID_PREFIX}#{item_class.to_s.downcase}_id", title: "#{item_class.to_s.camelize.constantize.find(object.send(rel_ids)).map(&:name).join(', ')}")
      end
    end
   end

  private

  def self.get_relation(params)
    if params[:object_item_relation].blank?
        return params[:item_class].pluralize
      end
      return params[:object_item_relation]
  end

end
