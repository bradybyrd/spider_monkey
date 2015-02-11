require 'spec_helper'

describe ApplicationPackage do
  it { should validate_presence_of(:app) }
  it 'validates that packages are only assigned once' do
    should validate_uniqueness_of(:package_id).
      scoped_to(:app_id).
      with_message('has already been added')
  end
end
