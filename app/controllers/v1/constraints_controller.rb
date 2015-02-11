class V1::ConstraintsController < V1::AbstractRestController

  def index
    @constraints = Constraint.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @constraints.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => constraints_presenter }
        format.json { render :json => constraints_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @constraint = Constraint.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @constraint.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => constraint_presenter }
        format.json { render :json => constraint_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @constraint = Constraint.new
    respond_to do |format|
      begin
        success = @constraint.update_attributes(params[:constraint])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => constraint_presenter, :status => :created }
        format.json  { render :json => constraint_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @constraint.errors, :status => :unprocessable_entity }
        format.json  { render :json => @constraint.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @constraint = Constraint.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @constraint
        begin
          success = @constraint.update_attributes(params[:constraint])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => constraint_presenter, :status => :accepted }
          format.json  { render :json => constraint_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        elsif
        format.xml  { render :xml => @constraint.errors, :status => :unprocessable_entity }
          format.json  { render :json => @constraint.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @constraint = Constraint.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @constraint
        success = @constraint.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => constraint_presenter, :status => :precondition_failed }
          format.json { render :json => constraint_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the constraints presenter
  def constraints_presenter
    @constraints_presenter ||= V1::ConstraintsPresenter.new(@constraints, @template)
  end

  # helper for loading the constraint present
  def constraint_presenter
    @constraint_presenter ||= V1::ConstraintPresenter.new(@constraint, @template)
  end
end
