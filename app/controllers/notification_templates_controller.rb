################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class NotificationTemplatesController < ApplicationController
  # GET /notification_templates
  # GET /notification_templates.xml

  before_filter :load_notification_template, :only => [:show,:edit,:update, :destroy]

  def index
    authorize! :list, NotificationTemplate.new

    @notification_templates = NotificationTemplate.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notification_templates }
    end
  end

  # GET /notification_templates/1
  # GET /notification_templates/1.xml
  def show
    authorize! :show, NotificationTemplate.new

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification_template }
    end
  end

  # GET /notification_templates/new
  # GET /notification_templates/new.xml
  def new
    authorize! :create, NotificationTemplate.new

    @notification_template = NotificationTemplate.new
    @supported_events = Notifier.supported_events
    @supported_formats = Notifier.supported_formats
    #prepare some help text arrays for available tokens
    @available_tokens = self.notification_tokens

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notification_template }
    end
  end

  # GET /notification_templates/1/edit
  def edit
    authorize! :edit, @notification_template

    @supported_events = Notifier.supported_events
    @supported_formats = Notifier.supported_formats
   
    #prepare some help text arrays for available tokens
    @available_tokens = self.notification_tokens
  end

  # POST /notification_templates
  # POST /notification_templates.xml
  def create
    @notification_template = NotificationTemplate.new(params[:notification_template])

    authorize! :create, @notification_template

    @supported_events = Notifier.supported_events
    @supported_formats = Notifier.supported_formats
    respond_to do |format|
      if @notification_template.save
        format.html { redirect_to(@notification_template, :notice => I18n.t(:'notification_template.notices.created')) }
        format.xml  { render :xml => @notification_template, :status => :created, :location => @notification_template }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notification_templates/1
  # PUT /notification_templates/1.xml
  def update
    authorize! :edit, @notification_template

    @supported_events = Notifier.supported_events
    @supported_formats = Notifier.supported_formats
    respond_to do |format|
      if @notification_template.update_attributes(params[:notification_template])
        format.html { redirect_to(@notification_template, :notice => I18n.t(:'notification_template.notices.updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @notification_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_templates/1
  # DELETE /notification_templates/1.xml
  def destroy
    authorize! :delete, @notification_template

    if @notification_template.destroy
      flash[:notice] = I18n.t(:'notification_template.notices.deleted')
    else
      flash[:error] = I18n.t(:'notification_template.errors.not_deleted')
    end

    respond_to do |format|
      format.html { redirect_to(notification_templates_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def load_notification_template
    begin
     @notification_template = NotificationTemplate.find(params[:id])
    rescue ActiveRecord::RecordNotFound
     flash[:error] = "Notification template not found"
      redirect_to :back
    end
  end
  
  def notification_tokens

    my_tokens = Hash.new
    passed_urls = Hash.new

    # get a common url for logging back into the system
    passed_urls[:login_url] = login_url(:host => Notifier.default_url_options[:host])

    # go ahead and build the tokens that don't need request urls
    my_tokens = {:user_event => Notifier.get_notification_parameters(User.first, passed_urls).keys,
      :exception_event => Notifier.get_notification_parameters(Exception.new, passed_urls).keys
    }

    # now build the url for requests
    sample_request = Request.find(:first, :include => :steps, :conditions => 'steps.id IS NOT NULL' )
    
    # possible for the system to have no requests, no steps, so wrap this in a null check
    unless sample_request.nil?

      passed_urls[:edit_request_url] = edit_request_url(sample_request, :host => Notifier.default_url_options[:host])
      passed_urls[:request_url] = request_url(sample_request, :host => Notifier.default_url_options[:host])

      # then finish off the array
      my_tokens[:request_event] = Notifier.get_notification_parameters(sample_request, passed_urls).keys
      
      sample_step = sample_request.try(:steps).try(:first)
      unless sample_step.nil?
        my_tokens[:step_event] = Notifier.get_notification_parameters(sample_step, passed_urls).keys
        my_tokens[:message_event] = Notifier.get_notification_parameters(sample_request, passed_urls).keys
      end
    else
      passed_urls[:edit_request_url] = []
      passed_urls[:request_url] = []

      # then finish off the array
      my_tokens[:request_event] = []
      my_tokens[:step_event] = []
      my_tokens[:message_event] = []
    end

    return my_tokens
  end
end
