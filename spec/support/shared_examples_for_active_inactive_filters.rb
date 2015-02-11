################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

shared_examples 'active' do
  it 'should contain only active' do
    should match_array(@active)
  end
end

shared_examples 'inactive' do
  it 'should contain only inactive' do
    should match_array(@inactive)
  end
end

shared_examples 'all' do
  it 'should contain both active and inactive' do
    should match_array(@active + @inactive)
  end
end

shared_examples 'empty' do
  it { should be_empty }
end

shared_examples 'active/inactive filter' do

  def get_names
    if @filter_flags.present?
      return @filter_flags
    else
      if @active[0].is_a? SoftDelete
        return :active, :inactive
      elsif @active[0].is_a? ArchivableModelHelpers
        return :unarchived, :archived
      else
        raise 'Only active/inactive and unarchived/archived supported'
      end
    end
  end

  before(:all) {
    @default_name, @custom_name = get_names
  }

  context 'filtered' do
    subject { described_class.filtered() }
    it_behaves_like 'active'
  end

  context 'filtered(active=true)' do
    subject { described_class.filtered(@default_name => 'true') }
    it_behaves_like 'active'
  end

  context 'filtered(active=false)' do
    subject { described_class.filtered(@default_name => 'false') }
    it_behaves_like 'empty'
  end

  context 'filtered(inactive=true)' do
    subject { described_class.filtered(@custom_name => 'true') }
    it_behaves_like 'inactive'
  end

  context 'filtered(active=true, inactive=true)' do
    subject { described_class.filtered(@default_name => 'true', @custom_name => 'true') }
    it_behaves_like 'all'
  end

  context 'filtered(active=false, inactive=true)' do
    subject { described_class.filtered(@default_name => 'false', @custom_name => 'true') }
    it_behaves_like 'inactive'
  end

end

