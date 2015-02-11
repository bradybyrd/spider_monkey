class V1::ListsController < V1::AbstractRestController
  def index
    @lists = List.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @lists.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => lists_presenter }
        format.json { render :json => lists_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @list = List.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @list.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => list_presenter }
        format.json { render :json => list_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @list = List.new
    respond_to do |format|
      begin
        success = @list.update_attributes(params[:list])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => list_presenter, :status => :created }
        format.json  { render :json => list_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
        format.json  { render :json => @list.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @list = List.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @list
        begin
        # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @list.toggle_archive
            @list.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          # otherwise continue on with a standard update
          elsif params[:list].present?
            success = @list.update_attributes(params[:list])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => list_presenter, :status => :accepted }
          format.json  { render :json => list_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
          format.json  { render :json => @list.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @list = List.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @list
        success = @list.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => list_presenter, :status => :precondition_failed }
          format.json { render :json => list_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the lists presenter
  def lists_presenter
    @lists_presenter ||= V1::ListsPresenter.new(@lists, @template)
  end

  # helper for loading the list present
  def list_presenter
    @list_presenter ||= V1::ListPresenter.new(@list, @template)
  end
end
