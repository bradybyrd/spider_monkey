################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PackageContent do

  context 'general' do
    describe 'validations' do
      before(:each) do
        @package_content = PackageContent.create(:name => 'pc001')
        @duplicate_for_uniq_validation = FactoryGirl.create(:package_content)
      end

      describe 'attribute normalizations' do
        it { should normalize_attribute(:name).from('  pc002  ').to('pc002') }
      end

      describe 'validations' do
        it { @package_content.should validate_presence_of(:name) }
        it { @package_content.should validate_uniqueness_of(:name) }
        it { @package_content.should ensure_length_of(:name).is_at_most(255) }
        it { @package_content.should ensure_length_of(:abbreviation).is_at_most(255) }

      end

      describe 'associations' do

        it 'should have many' do
          @package_content.should have_many(:request_package_contents)
          @package_content.should have_many(:requests)
        end

      end

      describe 'custom_methods' do

        describe 'when setting the insertion_point' do
          it 'should insert the application component at that point' do
            @package_content.should_receive(:insert_at).with(42)
            @package_content.insertion_point = 42
          end
        end

        describe 'when reading the insertion point' do
          it 'should return the position' do
            @package_content.position = 42
            @package_content.insertion_point.should == @package_content.position
          end
        end
      end
    end

    describe 'named scopes' do

      describe 'in_name_order' do
        it 'should return the lists in name order' do
          pc1 = create(:package_content, :name => 'zzzzzzzzz')
          pc2 = create(:package_content, :name => 'Apple')
          pc3 = create(:package_content, :name => 'Banana')
          results = PackageContent.in_name_order
          results.first.should == pc2
          results.last.should == pc1
        end
      end

      describe 'in_order' do
        it 'should return the lists in position order' do
          pc1 = create(:package_content)
          pc2 = create(:package_content)
          pc3 = create(:package_content)
          pc1.move_to_bottom
          pc2.move_to_top
          results = PackageContent.in_order
          results.first.should == pc2
          results.last.should == pc1
        end
      end
    end

    describe 'acts_as_archival' do
      describe 'should be archivable' do
        before(:each) do
          @package_content = create(:package_content)
        end
        it 'should archive' do
          @package_content.archived?.should be_falsey
          @package_content.archive
          @package_content.archived?.should be_truthy
        end

        it 'should be immutable when archived' do
          @package_content.archive
          @package_content.name = 'Test Mutability'
          @package_content.save.should be_falsey
        end

        it 'should unarchive' do
          @package_content.archive
          @package_content.archived?.should be_truthy
          @package_content.unarchive
          @package_content.archived?.should be_falsey
          @package_content.name = 'Test Mutability'
          @package_content.save.should be_truthy
        end

        it 'should have archival scopes' do
          @package_content2 = create(:package_content)
          @package_content2.archive
          PackageContent.count.should == 2
          PackageContent.archived.count.should == 1
          PackageContent.unarchived.count.should == 1
        end

        it 'should not archive if belongs to a functional request' do
          @request = create(:request)
          @package_content.requests << @request
          @package_content.requests.functional.count.should == 1
          PackageContent.unarchived.count.should == 1
          results = @package_content.archive
          results.should be_falsey
          PackageContent.unarchived.count.should == 1
        end

        it 'should allow archiving if it has no functional requests' do
          @request = create(:request)
          @package_content.requests << @request
          @request.destroy
          @package_content.requests.functional.count.should == 0
          PackageContent.unarchived.count.should == 1
          results = @package_content.archive
          results.should be_truthy
          PackageContent.unarchived.count.should == 0
          PackageContent.archived.count.should == 1
        end

      end
    end

    describe 'should not be destroyable unless archived and free of associations' do

      before(:each) do
        @package_content = create(:package_content)
      end

      it 'should not allow deletion if not archived' do
        @package_content.archived?.should be_falsey
        PackageContent.count.should == 1
        results = @package_content.destroy
        results.should be_falsey
        PackageContent.count.should == 1
      end

      it 'should allow deletion if archived and without requests' do
        PackageContent.count.should == 1
        @package_content.requests.count.should == 0
        @package_content.archive
        @package_content.archived?.should be_truthy
        results = @package_content.destroy
        results.should be_truthy
        PackageContent.count.should == 0
      end

    end
  end

  describe '#filtered' do

    before(:all) do
      PackageContent.delete_all
      @pc1 = create_package_content
      @pc2 = create_package_content(:name => 'Archived Package Content')
      @pc2.archive
      @pc2.reload
      @pc3 = create_package_content(:name => 'One more Package Content')
      @active = [@pc1, @pc3]
      @inactive = [@pc2]
    end

    after(:all) do
      PackageContent.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'One more Package Content')
        result.should match_array([@pc3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @pc2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @pc2.name)
        result.should match_array([@pc2])
      end
    end

  end

  protected

  def create_package_content(options = nil)
    create(:package_content, options)
  end

end

