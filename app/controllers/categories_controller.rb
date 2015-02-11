################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CategoriesController < ApplicationController

  before_filter :cleanup_blank_associated_events, :only => [:create, :update]

  # mixin to add an archive, unarchive action set
  include ArchivableController

  def index
    authorize! :list, Category.new
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @categories = Category.unarchived.name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_categories = Category.archived.name_order.paginate(:page => @page, :per_page => @per_page)
  end

  def new
    @category = Category.new
    authorize! :create, @category
  end

  def edit
    begin
      @category = find_category
      authorize! :edit, @category
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Category you are trying to access either does not exist or has been deleted"
      redirect_to(categories_path) && return
    end
  end

  def cleanup_blank_associated_events
    if params[:category] && params[:category][:associated_events]
      params[:category][:associated_events].reject!(&:blank?)
    end
  end

  def create
    @category = Category.new(params[:category])
    authorize! :create, @category

    if @category.save
      flash[:notice] = 'Category was successfully created.'
      redirect_to categories_path
    else
      render :action => "new"
    end
  end

  def update
    @category = find_category
    authorize! :edit, @category

    if @category.update_attributes(params[:category])
      flash[:notice] = 'Category was successfully updated.'
      redirect_to categories_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @category = find_category
    authorize! :delete, @category
    @category.destroy

    redirect_to categories_path
  end

  def associated_event_options
    case params[:category][:categorized_type]
    when 'request' then
      states = Request::EventsForCategories
    when 'step' then
      states = List.get_list_items("EventsForCategories")
    else
      states = []
    end

    render :text => ApplicationController.helpers.options_for_select(states.map { |s| [s.humanize, s] })
  end

  protected
    def find_category
      Category.find params[:id]
    end

end

