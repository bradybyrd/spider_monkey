################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ListItemsController < ApplicationController
  before_filter :find_list
  
  def create
    if @list.is_text?
      @list_item = ListItem.new(:value_text => params[:value].strip, :last_modified_by_id => current_user.id, :list_id => params[:list_id])
    else
      @list_item = ListItem.new(:value_num => params[:value].strip, :last_modified_by_id => current_user.id, :list_id => params[:list_id])
    end
    #FIXME: This should be a validation on the model and we should show errors in partial
    if params[:value].strip.empty?
      render :js => "alert('List item name not allowed to be empty');"
    else
      if @list_item.save
        #FIXME: This should be in an after hook not in controller or rest and automation additions to lists will not benefit
        List.reload_constant!(@list_item.list.name) # Reloads the constant that is using associated List Items
        render :update do |page|
          @list_items = ListItem.unarchived.name_order.find(:all, :conditions => "list_id = #{params[:list_id]}")
          page.replace "list_list_item_ids", :partial => "list_items/list_items", :locals => {:list => @list}
        page << "$('#value_item').val('')"
        end
      end
    end
  end
  
  def destroy
    @list_item = ListItem.delete_all("id in (#{params[:list_item_ids]})")
      render :update do |page|
        @list_items = ListItem.unarchived.name_order.find(:all, :conditions => "list_id = #{params[:list_id]}")
        page.replace "list_list_item_ids", :partial => "list_items/list_items", :locals => {:list => @list}
      end
  end
  
  private
  
  def find_list
    @list = List.find(params[:list_id])
  end
end

