class V1::RouteGatesController < V1::AbstractRestController
 
  def index
    @route_gates = RouteGate.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @route_gates.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => route_gates_presenter }
        format.json { render :json => route_gates_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  
  def show
    @route_gate = RouteGate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @route_gate.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => route_gate_presenter }
        format.json { render :json => route_gate_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @route_gate = RouteGate.new
    respond_to do |format|
      begin
        success = @route_gate.update_attributes(params[:route_gate])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => route_gate_presenter, :status => :created }
        format.json  { render :json => route_gate_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @route_gate.errors, :status => :unprocessable_entity }
        format.json  { render :json => @route_gate.errors, :status => :unprocessable_entity }
      end
    end
  end

  
  def update
    @route_gate = RouteGate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @route_gate
        begin
          success = @route_gate.update_attributes(params[:route_gate])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => route_gate_presenter, :status => :accepted }
          format.json  { render :json => route_gate_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        elsif
          format.xml  { render :xml => @route_gate.errors, :status => :unprocessable_entity }
          format.json  { render :json => @route_gate.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  
  def destroy
    @route_gate = RouteGate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @route_gate
        success = @route_gate.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => route_gate_presenter, :status => :precondition_failed }
          format.json { render :json => route_gate_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the route_gates presenter
  def route_gates_presenter
    @route_gates_presenter ||= V1::RouteGatesPresenter.new(@route_gates, @template)
  end

  # helper for loading the route_gate present
  def route_gate_presenter
    @route_gate_presenter ||= V1::RouteGatePresenter.new(@route_gate, @template)
  end
end
