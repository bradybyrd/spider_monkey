################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class OutputController < ApplicationController

  ALLOWED_FORMATS = %w(log txt htm html json)

  def render_output_file
    unless ALLOWED_FORMATS.include? params[:format]
      render nothing: true, status: :not_acceptable
    else
      remainder = params[:path] + '.' + params[:format]

      # Rails cannot render file which path includes unicode string
      # Workaround: read the file manually and render text;
      # Revert this in case any consequent problems, but
      # as a result link(that includes unicode chars) to automation result
      # in Request>>Step>>Note(after automation being run) won't work
      f_path = "#{$OUTPUT_BASE_PATH}/#{remainder}"
      unless File.exist? f_path
        @bad_url = request.url
        render :file => "#{Rails.root}/public/404.html", :status => :not_found
      else
        f_text = FileInUTF.open(f_path, 'r').read

        render :text => f_text

        #remainder = params[:path] + ".txt"
        #render :file => "#{$OUTPUT_BASE_PATH}/#{remainder}"
      end
    end
  end
end
