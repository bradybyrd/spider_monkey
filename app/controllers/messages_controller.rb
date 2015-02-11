################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class MessagesController < ApplicationController
  before_filter :find_request

  def new
    @message = @request.messages.build

    render :layout => false
  end

  def create
    @message = @request.messages.build(params[:message])
    @message.sender = current_user
    @message.request = @request

    if @message.save
      flash[:success] = "Message sent."

      if params[:start_request]
        @request.update_attribute(:notify_on_request_start, true)
        @request.update_attribute(:scheduled_at, Time.now) unless @request.scheduled_at?

        begin
          @request.start_request!
        rescue AASM::InvalidTransition
          logger.fatal("Invalid attempt to start request #{@request.number}")
        end
        begin
          Notifier.delay.request_started(@request, @message)
        rescue Exception => e
          logger.info("SS__ Email Notification Failed - #{e.message}")
        end
      end

      render :text => edit_request_path(@request)
    else
      flash.now[:error] = "Message not sent.  Body cannot be blank."
      render :template => 'messages/new', :status => 400, :layout => false
    end
  end

  protected

    def find_request
      @request = Request.find_by_number(params[:request_id])
    end
end

