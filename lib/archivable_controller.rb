################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ArchivableController

  def unarchive
    find_model_for_archive
    authorize_archivable_model
    if @archivable_model.respond_to?('aasm_state')
      if @archivable_model.may_retire?
        @archivable_model.retire!
      else
        @archivable_model.aasm_state = 'retired'
      end
    end

    success = @archivable_model.unarchive rescue nil if @archivable_model
    flash[:error] = "There was a problem unarchiving the #{get_model_name}." unless success
    respond_to do |wants|
      wants.html { redirect_to :action => :index, :page => params[:page],:key => params[:key] }
      wants.js { render :nothing => true }
    end
  end

  def archive
    find_model_for_archive
    authorize_archivable_model
    success = @archivable_model.archive if @archivable_model
    flash[:error] = "There was a problem archiving the #{get_model_name}." unless success

    respond_to do |wants|
      wants.html { redirect_to :action => :index, :page => params[:page],:key => params[:key] }
      wants.js { render :nothing => true }
    end
  end

  private

  # fires on a before
  def find_model_for_archive
    @archivable_model = get_model_name.classify.constantize.find params[:id] # rescue nil
  end

  def get_model_name
    self.class.to_s.gsub(/Controller$/, '').gsub(/Proces/,'Process').singularize.underscore
  end

  def authorize_archivable_model
    unauthorized! unless can?(:archive_unarchive, @archivable_model) ||
                         can?(:update_state, @archivable_model) ||
                         (@archivable_model.is_a?(Script) && can?(:update_state, :automation))
  end

  def unauthorized!
    authorize! :unauthorized, @archivable_model
  end

end
