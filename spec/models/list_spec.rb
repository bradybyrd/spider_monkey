################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe List do

  describe 'validations' do
    before(:each) do
      @list = List.new
      @uniqueness_test_list = FactoryGirl.create(:list)
    end

    it { @list.should validate_presence_of(:name) }
    it { @list.should validate_uniqueness_of(:name) }
    it { @list.should ensure_length_of(:name).is_at_most(255) }
  end

  describe 'normalizations' do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe 'named scopes' do

    describe 'sorted' do
      it 'should return the lists in name order' do
        list1 = create(:list, :name => 'Zanadoo')
        list2 = create(:list, :name => 'Apple')
        list3 = create(:list, :name => 'Banana')
        results = List.sorted
        results[0].should == list2
        results[1].should == list3
        results[2].should == list1
      end
    end

  end

  describe 'acts_as_archival' do
    describe 'should be archivable' do
      before(:each) do
        @list = create(:list)
      end
      it 'should archive' do
        @list.archived?.should be_falsey
        @list.archive
        @list.archived?.should be_truthy
      end

      it 'should be immutable when archived' do
        @list.archive
        @list.name = 'Test Mutability'
        @list.save.should be_falsey
      end

      it 'should unarchive' do
        @list.archive
        @list.archived?.should be_truthy
        @list.unarchive
        @list.archived?.should be_falsey
        @list.name = 'Test Mutability'
        @list.save.should be_truthy
      end

      it 'should have archival scopes' do
        @list2 = create(:list)
        @list2.archive
        List.count.should == 2
        List.archived.count.should == 1
        List.unarchived.count.should == 1
      end

      it 'should not archive if is required' do
        @required_list = FactoryGirl.create(:list, :name => 'Locations')
        List.unarchived.count.should == 2
        results = @required_list.archive
        results.should be_falsey
        List.unarchived.count.should == 2
      end

      it 'should allow archiving if is not required' do
        List.unarchived.count.should == 1
        results = @list.archive
        results.should be_truthy
        List.unarchived.count.should == 0
        List.archived.count.should == 1
      end

      it 'should also archive list items' do
        @list_item = FactoryGirl.create(:list_item, :list => @list)
        List.unarchived.count.should == 1
        ListItem.unarchived.count.should == 1
        results = @list.archive
        results.should be_truthy
        List.archived.count.should == 1
        ListItem.archived.count.should == 1
        List.unarchived.count.should == 0
        ListItem.unarchived.count.should == 0
      end
    end
  end

  describe 'destroy method' do

    before(:each) do
      @list = create(:list)
    end

    it 'should not allow deletion if not archived or required' do
      List.count.should == 1
      @list.archived?.should be_falsey
      results = @list.destroy
      results.should be_falsey
      List.count.should == 1
    end

    it 'should allow deletion if archived and not required' do
      List.count.should == 1
      @list.archive
      @list.required?.should be_falsey
      @list.archived?.should be_truthy
      results = @list.destroy
      results.should be_truthy
      List.count.should == 0
    end

    it 'should also delete list items' do
      @list_item = FactoryGirl.create(:list_item, :list => @list)
      List.count.should == 1
      ListItem.count.should == 1
      @list.archive
      @list.required?.should be_falsey
      @list.archived?.should be_truthy
      results = @list.destroy
      results.should be_truthy
      List.count.should == 0
      ListItem.count.should == 0
    end
  end

  describe '#filtered' do

    before(:all) do
      List.delete_all
      @list1 = create_list
      @list2 = create_list(:name => 'Archived List')
      @list2.archive
      @list2.reload
      @list3 = create_list(:name => 'Simple List')
      @active = [@list1, @list3]
      @inactive = [@list2]
    end

    after(:all) do
      List.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Simple List')
        result.should match_array([@list3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @list2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @list2.name)
        result.should match_array([@list2])
      end
    end

  end

  describe 'hash like' do
    it 'should be stored as #is_hash' do
      list = List.create name: 'HashLike', is_text: 0, is_hash: 1
      list.reload.is_hash.should be true
    end
  end

  describe '#get_list_items' do
    let(:list)      { create :list, name: 'Rammstein', is_text: true }
    let(:list_item) { create :list_item, list_id: list.id, value_text: 'Benzin' }

    it 'should return ["empty list"] if list was not found' do
      expect(List.get_list_items 'nonexisting').to eq ['empty list']
    end

    it 'should raise an exception if wrong argument type given' do
      expect{List.get_list_items 1}.to raise_error ArgumentError
    end

    it 'should return list item successfully' do
      expect(list_item.list).to eq list
      expect(List.get_list_items 'Rammstein').to eq ['Benzin']
    end
  end

  describe '#list_items_by_type' do
    let(:list_num)       { create :list, name: 'ListNumeric', is_text: false }
    let(:list_text)      { create :list, name: 'ListText', is_text: true }
    let(:list_hash)      { create :list, name: 'ListHash', is_text: false, is_hash: true }
    let(:list_item_num)  { create :list_item, list_id: list_num.id, value_num: 2 }
    let(:list_item_text) { create :list_item, list_id: list_text.id, value_text: 'text' }
    let(:list_item_hash) { create :list_item, list_id: list_hash.id, value_text: 'k1', value_num: 1 }

    it 'should return array of [value_text, value_num] for hash like list' do
      expect(list_item_hash.list).to eq list_hash
      expect(List.get_list_items 'ListHash').to eq [['k1', 1]]
    end

    it 'should return text value for text like list' do
      expect(list_item_num.list).to eq list_num
      expect(List.get_list_items 'ListNumeric').to eq [2]
    end

    it 'should return num value for numeric like list' do
      expect(list_item_text.list).to eq list_text
      expect(List.get_list_items 'ListText').to eq ['text']
    end

    it 'should return ["empty list"] for empty list' do
      expect(list_num.list_items).to be_empty
      expect(List.get_list_items 'ListNumeric').to eq ['empty list']
    end

    it 'should return only unarchived list_items' do
      li = create :list_item, list_id: list_hash.id, value_text: 'k2', value_num: 2
      li.archive
      expect(list_item_hash.list).to eq list_hash
      expect(List.get_list_items 'ListHash').to eq [['k1', 1]]
    end

    context 'sorting results' do
      it 'should be able to sort result for hash' do
        create :list_item, list_id: list_hash.id, value_text: 'k2', value_num: 0
        expect(list_item_hash.list).to eq list_hash
        expect(List.get_list_items 'ListHash', sort_by: proc{|key_value| key_value[1]}).to eq [['k2', 0], ['k1', 1]]
      end

      it 'should be able to sort result for hash' do
        create :list_item, list_id: list_num.id, value_num: 0
        expect(list_item_num.list).to eq list_num
        expect(List.get_list_items 'ListNumeric', sort_by: proc{|int| int}).to eq [0,2]
      end

      it 'should be able to sort result for hash' do
        create :list_item, list_id: list_text.id, value_text: 'atext'
        expect(list_item_text.list).to eq list_text
        expect(List.get_list_items 'ListText', sort_by: proc{|text| text}).to eq %w(atext text)
      end
    end
  end

  describe '#view_object' do
    it{ should respond_to :view_object }
  end

  protected

  def create_list(options = nil)
    create(:list, options)
  end
end

