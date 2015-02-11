################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ListsController < ApplicationController
  # mixin to add an archive, unarchive action set
  include ArchivableController

  before_filter :find_list, :only => [:edit, :destroy, :update]
  
  def index
    authorize! :list, List.new

    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @lists = List.unarchived.sorted.paginate(:page => @page, :per_page => @per_page)
    @archived_lists = List.archived.sorted.paginate(:page => @page, :per_page => @per_page)
  end
  
  def new
    authorize! :create, List.new

    @list = List.new
    @list_item = ListItem.new
    render :layout => false
  end
  
  def create
    authorize! :create, List.new

    list_params = params[:list].merge created_by_id: current_user.id
    @list       = List.new list_params
    if @list.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.list'))
    else
      flash[:error] = I18n.t(:'list.validations.had_errors', errors: gather_errors(@list))
    end
    redirect_to lists_path
  end

  def edit
    authorize! :edit, List.new

    @list_items = @list.list_items.unarchived.name_order
    @inactive_list_items = @list.list_items.archived.name_order
    render :layout => false
  end
    
  def destroy
    authorize! :delete, List.new

    if @list.destroy
      flash[:success] = I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.list'))
      redirect_to lists_path
    end
  end
  
  
  # FIXME: Temporary patch to all the out of date javascript based validation which is
  # inferior to the model based validation and out of sync with it.  Ideally, this
  # would redirect as ajax back to the form but I do not have time to finish that repair.

  
  def update
    authorize! :edit, List.new

    if @list.update_attributes(:name => params[:list][:name])
      all_list_ids = params[:active_list_items].split(',')
      all_list_ids.each do |list_item_id|
        list_item = create_or_find_list_item(@list, list_item_id)
        list_item.try(:archive) if list_item
      end
      all_list_ids = params[:inactive_list_items].split(',')
      all_list_ids.each do |list_item_id|
        list_item = create_or_find_list_item(@list, list_item_id)
        list_item.try(:unarchive) if list_item
      end
      flash[:notice] = I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.list'))
    else
    # FIXME: Validation errors should print on this form?
      flash[:error] = I18n.t(:'list.validations.had_errors', errors: gather_errors(@list))
    end
    redirect_to lists_path
  end
  
  private

  def find_list
    @list = List.find(params[:id])
  end

  # FIXME: This is a poor substitute for reloading javascript window and showing errors in normal place
  def gather_errors(passed_list)
    full_message = []
    passed_list.errors.full_messages.each do |message|
      full_message << message
    end
    return full_message.join("\n")
  end
  
  # FIXME: Move to an attribute access on the model that builds these and reports validation errors
  # what is added here now for lack of time is a drying up of some problematic code from earlier.
  def create_or_find_list_item(list, list_item_id = "")
    logger.info("Trying to create: " + list_item_id + "in list: " + list.name)
    # the multi-selects use a 00_ prefix to designate new items created in the form
    if list_item_id.index("00_") == 0
      #list_item = list_item[0,2]="";
      value_text = list_item_id.split('_',2)[1]
      if list.is_hash? and !list.is_text?
        key, value = value_text.split(':', 2)
        list_item = ListItem.create :value_text => key, :value_num => value.try(:to_i),
                                    :last_modified_by_id => current_user.id, :list_id => params[:id]
      elsif list.is_text?
        list_item = ListItem.create(:value_text => value_text, :last_modified_by_id => current_user.id, :list_id => params[:id])
      else
        list_item = ListItem.create(:value_num => value_text.to_i, :last_modified_by_id => current_user.id, :list_id => params[:id])
      end
      unless list_item.valid?
        flash[:error] = "There were validation errors creating new list items: " + gather_errors
      end
    else
      list_item = ListItem.find(list_item_id) rescue nil
    end
    return list_item
  end  
end
