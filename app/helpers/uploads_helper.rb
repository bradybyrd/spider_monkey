################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module UploadsHelper
  def link_to_upload(upload)
    link_to h(label_to_upload(upload)), upload, :class => "upload_#{upload.id}", :title => "#{upload.attachment_identifier} (#{upload.find_uploader})"
  end

  def link_to_upload_list(model)
    unless model.uploads.blank?
      model.uploads.map { |upload| link_to_upload upload }.to_sentence
    else
      raw("&nbsp;")
    end
  end

  def label_to_upload(upload)
    h(truncate(upload.attachment_identifier, :length =>  35))
  end

  def label_to_upload_list(model)
    model.uploads.map { |upload| "<p>#{ label_to_upload upload }<br/> #{upload.find_uploader}<br/></p>" }
  end

  def add_step_asset_link(model)
    if model.is_a?(Step)
      link_to raw('add upload'), add_uploads_form_request_step_path(model.request, model, :upload => "step"), :rel => 'facebox[]'
    else
      "&nbsp;"
    end
  end

end

