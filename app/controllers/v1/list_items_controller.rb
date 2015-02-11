class V1::ListItemsController < V1::AbstractRestController
  def index
    @list_items = ListItem.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @list_items.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => list_items_presenter }
        format.json { render :json => list_items_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @list_item = ListItem.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @list_item.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => list_item_presenter }
        format.json { render :json => list_item_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @list_item = ListItem.new
    respond_to do |format|
      begin
        success = @list_item.update_attributes(params[:list_item])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => list_item_presenter, :status => :created }
        format.json  { render :json => list_item_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @list_item.errors, :status => :unprocessable_entity }
        format.json  { render :json => @list_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @list_item = ListItem.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @list_item
        begin
        # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @list_item.toggle_archive
            @list_item.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          # otherwise continue on with a standard update
          elsif params[:list_item].present?
            success = @list_item.update_attributes(params[:list_item])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => list_item_presenter, :status => :accepted }
          format.json  { render :json => list_item_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @list_item.errors, :status => :unprocessable_entity }
          format.json  { render :json => @list_item.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @list_item = ListItem.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @list_item
        success = @list_item.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => list_item_presenter, :status => :precondition_failed }
          format.json { render :json => list_item_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the list_items presenter
  def list_items_presenter
    @list_items_presenter ||= V1::ListItemsPresenter.new(@list_items, @template)
  end

  # helper for loading the list_item present
  def list_item_presenter
    @list_item_presenter ||= V1::ListItemPresenter.new(@list_item, @template)
  end
end
