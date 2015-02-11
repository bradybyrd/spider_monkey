################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::DeploymentWindow::SeriesCollectionPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :series_collection

  # overwrite the default json to provide a unique hash with child objects
  # def as_json( options = nil )
  # custom_hash.as_json
  # end

  # # overwrite the default XML to provide a unique string with child objects
  def to_xml( options = {})
    options.merge!(root: :series_collection, children: :series_item)
    @resource.to_xml( default_options.merge(options) )
  end

  # # underlying logic for assembling the correct serialized hash
  # def custom_hash
  # data_hash = {
  # :id => user.id,
  # :name => user.name
  # }
  # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def user
  # Api::V1::ResourcePresenter.new( user.users ).as_json( false )
  # end

  private

  def resource_options
    # TODO: What should be included here?

    { only: safe_attributes#, :include => {
        # :request => { :only => [:id, :name, :aasm_state]},
        # :user => { :only => [:id, :email, :login]},
        # :step => { :only => [:id, :name, :aasm_state]}
      # }
    }
  end

  def safe_attributes
    # TODO: frequency, recurrent

    # :behavior, :finish, :name, :recurrent, :schedule, :start, :duration_in_days,
    #               :environment_ids, :frequency

    [
      :id, :name, :behavior, :start_at, :finish_at,
      :archive_number, :archived_at, :duration_in_days,
      :environment_ids, :recurrent, :frequency, :aasm_state,
      :created_by
    ]
  end

end
