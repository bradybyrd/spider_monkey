################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ListItem do

  describe 'validations' do
    before(:each) do
      @list_item = ListItem.new
    end

    # attribute normalizer will truncate since showing errors is hard for list_items
    # it { @list_item.should ensure_length_of(:value_text).is_at_most(256) }

    it { @list_item.should validate_numericality_of(:value_num) }
  end

  describe 'normalizations' do
    it { should normalize_attribute('value_text').from('  Hello  ').to('Hello') }
  end

  describe 'named scopes' do

    describe 'name_order' do
      it 'should return the lists in name order' do
        list_item1 = create(:list_item, :value_text => 'Zanadoo')
        list_item2 = create(:list_item, :value_text => 'Apple')
        list_item3 = create(:list_item, :value_text => 'Banana')
        results = ListItem.name_order
        results[0].should == list_item2
        results[1].should == list_item3
        results[2].should == list_item1
      end
    end

  end

  describe 'acts_as_archival' do
    describe 'should be archivable' do
      before(:each) do
        @list_item = create(:list_item)
      end
      it 'should archive' do
        @list_item.archived?.should be_falsey
        @list_item.archive
        @list_item.archived?.should be_truthy
      end

      it 'should be immutable when archived' do
        @list_item.archive
        @list_item.value_text = 'Test Mutability'
        @list_item.save.should be_falsey
      end

      it 'should unarchive' do
        @list_item.archive
        @list_item.archived?.should be_truthy
        @list_item.unarchive
        @list_item.archived?.should be_falsey
        @list_item.value_text = 'Test Mutability'
        @list_item.save.should be_truthy
      end

      it 'should have archival scopes' do
        @list_item2 = create(:list_item)
        @list_item2.archive
        ListItem.count.should == 2
        ListItem.archived.count.should == 1
        ListItem.unarchived.count.should == 1
      end

    end
  end

  describe 'destroy method' do

    before(:each) do
      @list_item = create(:list_item)
    end

    it 'should not allow deletion if not archived or required' do
      ListItem.count.should == 1
      @list_item.archived?.should be_falsey
      results = @list_item.destroy
      results.should be_falsey
      ListItem.count.should == 1
    end

    it 'should allow deletion if archived' do
      ListItem.count.should == 1
      @list_item.archive
      @list_item.archived?.should be_truthy
      results = @list_item.destroy
      results.should be_truthy
      ListItem.count.should == 0
    end

  end

  describe '#filtered' do

    before(:all) do

      ListItem.delete_all
      @list1 = create(:list, :name => 'Default List')
      @list2 = create(:list, :name => 'Custom List')

      @list_item1 = create_list_item(:value_text => 'item 1', :list => @list1)
      @list_item2 = create_list_item(:value_text => 'item 1', :list => @list1)
      @list_item2.archive
      @list_item3 = create_list_item(:value_num => 42, :list => @list1)
      @list_item4 = create_list_item(:value_num => 42, :list => @list1)
      @list_item4.archive
      @list_item5 = create_list_item(:value_text => 'new item', :value_num => 357, :list => @list1)

      @list_item21 = create_list_item(:value_text => 'item 1', :list => @list2)
      @list_item22 = create_list_item(:value_text => 'item 1', :list => @list2)
      @list_item22.archive
      @list_item23 = create_list_item(:value_num => 42, :list => @list2)
      @list_item24 = create_list_item(:value_num => 42, :list => @list2)
      @list_item24.archive
      @list_item26 = create_list_item(:value_text => 'new item', :value_num => 357, :list => @list2)
      @list_item26.archive

      @active = [@list_item1, @list_item3, @list_item5, @list_item21, @list_item23]
      @inactive = [@list_item2, @list_item4, @list_item22, @list_item24, @list_item26]
    end

    after(:all) do
      ListItem.delete_all
      List.delete([@list1, @list2])
    end

    it_behaves_like 'active/inactive filter' do

      describe 'filter by value_text' do
        subject { described_class.filtered(:value_text => 'item 1') }
        it { should match_array([@list_item1, @list_item21]) }
      end

      describe 'filter by value_num' do
        subject { described_class.filtered(:value_num => 42) }
        it { should match_array([@list_item3, @list_item23]) }
      end

      describe 'filter by list_id' do
        subject { described_class.filtered(:list_id => @list1.id) }
        it { should match_array([@list_item1, @list_item3, @list_item5]) }
      end

      describe 'filter by list_name' do
        subject { described_class.filtered(:list_name => @list2.name) }
        it { should match_array([@list_item21, @list_item23]) }
      end


      describe 'filter by value_text, list_name and list_id' do
        subject { described_class.filtered(:value_text => 'item 1', :list_name => @list2.name, :list_id => @list2.id) }
        it { should match_array([@list_item21]) }
      end

      describe 'filter by value_num, list_name and list_id' do
        subject { described_class.filtered(:value_num => 42, :list_name => @list1.name, :list_id => @list1.id) }
        it { should match_array([@list_item3]) }
      end

      describe 'filter by different list_name and list_id' do
        subject { described_class.filtered(:list_name => @list1.name, :list_id => @list2.id) }
        it { should be_empty }
      end

      describe 'filter by value_text, value_num, list_name and list_id' do
        subject { described_class.filtered(:value_text => 'new item', :value_num => 357, :list_name => @list1.name, :list_id => @list1.id) }
        it { should match_array([@list_item5]) }
      end

      describe 'filter(archived) by value_text, value_num, list_name and list_id' do
        subject { described_class.filtered(:archived => true, :value_text => 'new item', :value_num => 357, :list_name => @list2.name, :list_id => @list2.id) }
        it { should match_array([@list_item26]) }
      end

    end
  end

  protected

  def create_list_item(options = nil)
    create(:list_item, options)
  end

end

