################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class UploadsController < ApplicationController
  def show
    file_exists = false
    @upload = Upload.find(params[:id])
    if @upload
      my_path_1 = File.join(@upload.attachment.root, @upload.attachment_url)
      relative_path = ("%08d" % @upload.id).scan(/..../) + [@upload.filename]
      my_path_2 = File.join(@upload.attachment.root, "assets", relative_path)

      if File.exist?(my_path_1)
        my_path = my_path_1
      elsif File.exist?(my_path_2)
        my_path = my_path_2
      else
        my_path = nil
      end

      if my_path
        file_exists = true
        File.open(my_path, 'rb') do |f|
          if @upload.content_type
            send_data f.read, :filename => File.basename(my_path), :type => @upload.content_type, :stream => false
          else
            send_data f.read, :filename => File.basename(my_path), :stream => false
          end
        end
      end
    end

    if file_exists == false
      flash[:error] = "File for upload id #{ params[:id] } could not be found."
      redirect_to :back
    end
  end

  def destroy
    if params[:request_id].present?
      @request = Request.find(params[:request_id])
      @request.uploads.destroy(@request.uploads.find(params[:id]))
      render :partial => "update_uploads", :locals => { :request => @request }
    elsif params[:activity_id].present?
      @activity = Activity.find(params[:activity_id])
      @activity.uploads.destroy(@activity.uploads.find(params[:id]))
      redirect_to :back
    else
      @step = Step.find(params[:step_id])
      @step.uploads.destroy(@step.uploads.find(params[:id]))
      render :partial => "steps/step_rows/update_uploads", :locals => { :step => @step }
    end

  end

end

