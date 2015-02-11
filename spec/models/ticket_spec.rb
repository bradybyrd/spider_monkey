################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe Ticket do

  describe "validations" do

    before(:each) do
      @ticket = create(
        :ticket,
        :project_server => create(:project_server),
        :name => "This is a sample ticket",
        :foreign_id => "Sample ticket"
      )
    end

    it "should create a new instance given valid attributes" do
      @ticket.should be_valid
    end

    shared_examples "has validatable attribute" do
      it "isn't valid" do
        @ticket.send("#{attribute}=".to_sym, nil)
        @ticket.should_not be_valid
      end
      it "can't save without validation" do
        expect { @ticket.update_attribute(attribute, nil)  }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    context "when foreign id is nil" do
      let(:attribute) { "foreign_id" }
      it_behaves_like "has validatable attribute"
    end

    context "when name is nil" do
      let(:attribute) { "name" }
      it_behaves_like "has validatable attribute"
    end

    context "when status is nil" do
      let(:attribute) { "status" }
      it_behaves_like "has validatable attribute"
    end

    it "should require a unique foreign_id for same project server" do
      @duplicate_ticket = build(:ticket, @ticket.attributes )
      @duplicate_ticket.should_not be_valid
    end

    it "should allow same foreign_id for different project server" do
      @sample_attributes = @ticket.attributes
      @sample_attributes['id'] = nil
      @sample_attributes['project_server_id'] = create(:project_server).id
      @new_ticket = create(:ticket, @sample_attributes)
      @new_ticket.should be_valid
    end

    it "should not allow foreign_id to be more than 50 characters" do
      @ticket.foreign_id = "ffffffffffffffffffffffffffffffffffffffffffffddddddd"
      @ticket.should_not be_valid
    end

    it "should not allow name to be more than 250 characters" do
      @ticket.name = "ffffffffffffffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddsjdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
      @ticket.should_not be_valid
    end

    it "should not allow status to be more than 125 characters" do
      @ticket.status = "ffffffffffffffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddsjdddddddddddddddddddddddddddddddddddddddddddddddss"
      @ticket.should_not be_valid
    end

    it "should not allow ticket_type to be more than 100 characters" do
      @ticket.ticket_type = "ffffffffffffffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddsjdddddddddddddddddddddddd"
      @ticket.should_not be_valid
    end

  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:foreign_id).from('  GEADE 1234  ').to('GEADE 1234') }
    it { should normalize_attribute(:ticket_type).from('  Release Contents  ').to('Release Contents') }
    it { should normalize_attribute(:status).from('  Completed  ').to('Completed') }
    it { should normalize_attribute(:url).from('http://www.rally.com/?id=abc').to('http://www.rally.com/?id=abc') }
    it { should normalize_attribute(:url).from('ftp://www.rally.com/?id=abc').to('ftp://www.rally.com/?id=abc') }
    it { should normalize_attribute(:url).from('www.rally.com/?id=abc').to('http://www.rally.com/?id=abc') }
    it { should normalize_attribute(:url).from('rally.com/?id=abc').to('http://rally.com/?id=abc') }
  end

  describe "associations" do
    before(:each) do
      @ticket = create(:ticket,
        :project_server => create(:project_server),
        :name => "This is a sample ticket",
        :foreign_id => "Sample ticket"
      )
      @user = create(:user)
      User.stub(:current_user) { @user }
    end

    it "should present current value of plans or look it up from associated plans" do
      @lc1 = create(:plan, :name => "LC 1")
      @lc2 = create(:plan, :name => "LC 2")
      @ticket.plans << [@lc1, @lc2]
      @ticket.plans.count.should == 2
      @ticket.plan_ids.length.should == 2
      @ticket.plan_ids.should include(@lc1.id)
      @ticket.plan_ids.should include(@lc2.id)
    end

    it "should save related plans if passed ids to plan_ids" do
      @lc1 = create(:plan, :name => "LC 1")
      @lc2 = create(:plan, :name => "LC 2")
      @ticket.plan_ids = [@lc1.id, @lc2.id]
      @ticket.plans.count.should == 2
      @ticket.plan_ids.should include(@lc1.id)
      @ticket.plan_ids.should include(@lc2.id)
      @ticket.plans.map{ |l| l.name }.should include(@lc1.name)
      @ticket.plans.map{ |l| l.name }.should include(@lc2.name)
    end

    it "should clear related objects if passed empty array for ids after update" do
      @plan = create(:plan, :name => "LC test")
      @ticket.plans << @plan
      @ticket.plans.count.should == 1
      @ticket.update_attributes(:plan_ids => "")
      @ticket.plans.count.should == 0
    end

    it "should present current value of steps or look it up from associated steps" do
      @s1 = create(:step, :name => "Step 1")
      @s2 = create(:step, :name => "Step 2")
      @ticket.steps << [@s1, @s2]
      @ticket.steps.count.should == 2
      @ticket.step_ids.length.should == 2
      @ticket.step_ids.should include(@s1.id)
      @ticket.step_ids.should include(@s2.id)
    end

    it "should save related steps if passed ids to step_ids" do
      @s1 = create(:step, :name => "Step 1")
      @s2 = create(:step, :name => "Step 2")
      @ticket.step_ids = [@s1.id, @s2.id]
      @ticket.steps.count.should == 2
      @ticket.step_ids.should include(@s1.id)
      @ticket.step_ids.should include(@s2.id)
      @ticket.steps.map{ |l| l.name }.should include(@s1.name)
      @ticket.steps.map{ |l| l.name }.should include(@s2.name)
    end

    it "should clear related objects if passed empty array for ids after update" do
      @step = create(:step, :name => "Test Step")
      @ticket.steps << @step
      @ticket.steps.count.should == 1
      @ticket.step_ids = ""
      @ticket.steps.count.should == 0
    end

    it "should present current value of steps or look it up from related tickets" do
      @t1 = create(:ticket)
      @t2 = create(:ticket)
      @ticket.related_tickets << [@t1, @t2]
      @ticket.related_tickets.count.should == 2
      @ticket.related_ticket_ids.length.should == 2
      @ticket.related_ticket_ids.should include(@t1.id)
      @ticket.related_ticket_ids.should include(@t2.id)
    end

    it "should save related tickets if passed ids to related_tickets_ids" do
      @t1 = create(:ticket)
      @t2 = create(:ticket)
      @ticket.related_ticket_ids = [@t1.id, @t2.id]
      @ticket.related_tickets.count.should == 2
      @ticket.related_ticket_ids.should include(@t1.id)
      @ticket.related_ticket_ids.should include(@t2.id)
      @ticket.related_tickets.map{ |l| l.name }.should include(@t1.name)
      @ticket.related_tickets.map{ |l| l.name }.should include(@t2.name)
    end

    it "should clear related objects if passed empty array for ids after update" do
      @related_ticket = create(:ticket)
      @ticket.related_tickets << @related_ticket
      @ticket.related_tickets.count.should == 1
      @ticket.related_ticket_ids = ""
      @ticket.related_tickets.count.should == 0
    end
  end

  describe "named scopes" do
    describe "#ticket_type" do
      it "should return all tickets with specified ticket type" do
        ticket = create(:ticket, :ticket_type => 'Operations')
        Ticket.by_ticket_type('Operations').should include(ticket)
      end

      it "should not return tickets that do not match specified ticket type" do
        ticket = create(:ticket, :ticket_type => 'Release Contents')
        Ticket.by_ticket_type('Operations').should_not include(ticket)
      end

      it "should return tickets that all specified ticket types" do
        t1 = create(:ticket, :ticket_type => 'Release Contents')
        t2 = create(:ticket, :ticket_type => 'Operations')
        t3 = create(:ticket, :ticket_type => 'General')
        Ticket.by_ticket_type(['Operations', 'Release Contents']).should include(t1)
        Ticket.by_ticket_type(['Operations', 'Release Contents']).should include(t2)
        Ticket.by_ticket_type(['Operations', 'Release Contents']).should_not include(t3)
      end

    end

    describe "#foreign_id" do
      it "should return all tickets with specified foreign_id" do
        ticket = create(:ticket, :foreign_id => 'GEADE 1123')
        Ticket.by_foreign_id('GEADE 1123').should include(ticket)
        Ticket.by_foreign_id('GEADE 1124').should_not include(ticket)
      end

      it "should return all tickets that match specified foreign ids" do
        t1 = create(:ticket, :foreign_id => 'GEADE 1123')
        t2 = create(:ticket, :foreign_id => 'GEADE 1124')
        t3 = create(:ticket, :foreign_id => 'GEADE 1125')
        Ticket.by_foreign_id(['GEADE 1123', 'GEADE 1124']).should include(t1)
        Ticket.by_foreign_id(['GEADE 1123', 'GEADE 1124']).should include(t2)
        Ticket.by_foreign_id(['GEADE 1123', 'GEADE 1124']).should_not include(t3)
      end
    end

    describe "#integration" do
      it "should return all tickets that match specified integration" do
        project_server1 = create(:project_server)
        project_server2 = create(:project_server)
        t1 = create(:ticket, :project_server => project_server1)
        t2 = create(:ticket, :project_server => project_server2)
        Ticket.by_integration(project_server1.id).should include(t1)
        Ticket.by_integration(project_server2.id).should_not include(t1)
        Ticket.by_integration(project_server2.id).should include(t2)
      end
    end

    describe "#by_request_id" do
      it "should return all tickets that match specified request id" do
        @s1 = create(:step, :name => "Step 1", :request_id => 10)
        @s2 = create(:step, :name => "Step 2", :request_id => 14)
        t1 = create(:ticket, :step_ids => [@s1.id])
        t2 = create(:ticket, :step_ids => [@s2.id])
        Ticket.by_request_id(10).should include(t1)
        Ticket.by_request_id(10).should_not include(t2)
        Ticket.by_request_id(14).should include(t2)
        Ticket.by_request_id([10, 14]).should include(t1)
        Ticket.by_request_id([10, 14]).should include(t2)
      end
    end

    describe "#by_step_id" do
      it "should return all tickets that match specified step id" do
        @s1 = create(:step, :name => "Step 1", :request_id => 10)
        @s2 = create(:step, :name => "Step 2", :request_id => 14)
        t1 = create(:ticket, :step_ids => [@s1.id])
        t2 = create(:ticket, :step_ids => [@s2.id])
        Ticket.by_step_id(@s1.id).should include(t1)
        Ticket.by_step_id(@s1.id).should_not include(t2)
        Ticket.by_step_id(@s2.id).should include(t2)
        Ticket.by_step_id([@s1.id, @s2.id]).should include(t1)
        Ticket.by_step_id([@s1.id, @s2.id]).should include(t2)
      end
    end

    describe "#by_plan_id" do
      it "should return all tickets that match specified plan id" do
        l1 = create(:plan)
        l2 = create(:plan)

        t1 = create(:ticket, :plan_ids => [l1.id])
        t2 = create(:ticket, :plan_ids => [l2.id])

        Ticket.by_plan_id(l1.id).should include(t1)
        Ticket.by_plan_id(l1.id).should_not include(t2)
        Ticket.by_plan_id(l2.id).should include(t2)
        Ticket.by_plan_id([l1.id, l2.id]).should include(t1)
        Ticket.by_plan_id([l1.id, l2.id]).should include(t2)
      end
    end
  end

  describe "accepts nested attributes for associated objects:" do
    describe "extended attributes creation" do
      it { expect { create(:ticket, :extended_attributes_attributes => [{:name => 'Severity', :value_text => 'High'}]) }.to change(ExtendedAttribute, :count).by(1) }
    end
  end

  describe "methods" do
    describe 'filtered by' do
      before(:all) do
        @ticket1 = create(:ticket, project_server: create(:project_server))
        @ticket2 = create(:ticket, project_server: @ticket1.project_server)
        @ticket3 = create(:ticket)
      end

      it "project_server_id" do; Ticket.filtered(nil, {project_server_id: @ticket1.project_server.id}).should =~ [@ticket1, @ticket2] end
    end
    it "types for select" do
      t1 = create(:ticket, :ticket_type => 'General')
      t2 = create(:ticket, :ticket_type => 'Operations')
      t3 = create(:ticket, :ticket_type => 'Release Contents')

      Ticket.types_for_select.count.should == 3
    end
  end

  describe '#filtered' do

    before(:all) do
      Ticket.delete_all
      @app_1 = create(:app, :name => 'App 1')
      @app_2 = create(:app, :name => 'App 2')

      @p1 = create(:plan)
      @p2 = create(:plan)

      @s1 = create(:step, :name => 'Step 1', :request_id => 5)

      @ps = create(:project_server)

      @t_1 = create_ticket(:app => @app_1, :plans => [@p1, @p2], :ticket_type => 'Type #1')
      @t_2 = create_ticket(:app => @app_2, :steps => [@s1], :name => 'Sample TICKET')
      @t_3 = create_ticket(:foreign_id => 'Sample ticket', :ticket_type => 'Release Contents', :project_server => @ps)
    end

    describe 'filter by default' do
      subject { described_class.filtered() }
      it { should match_array([@t_1, @t_2, @t_3]) }
    end

    describe 'filter by app_name, plan_id' do
      subject { described_class.filtered(nil, {:app_name => @app_1.name,
                                               :plan_id => @p2.id}) }
      it { should match_array([@t_1]) }
    end

    describe 'filter by app_id, step_id, request_id' do
      subject { described_class.filtered(nil, {:app_id => @app_2.id,
                                               :step_id => @s1.id,
                                               :request_id => @s1.request_id}) }
      it { should match_array([@t_2]) }
    end

    describe 'filter by foreign_id, project_server_id' do
      subject { described_class.filtered(nil, {:foreign_id => 'Sample ticket',
                                               :project_server_id => @ps.id}) }
      it { should match_array([@t_3]) }
    end

    describe 'filter by ticket_type' do
      subject { described_class.filtered(nil, :ticket_type => ['Type #1', 'Release Contents']) }
      it { should match_array([@t_1, @t_3]) }
    end

    describe 'filter by search_keyword' do
      subject { described_class.filtered(nil, {}, 'Sample ticket') }
      it { should match_array([@t_2, @t_3]) }
    end

    describe 'filter by tickets and search_keyword' do
      subject do
        ticket_by_keyword = described_class.filtered(nil, {}, 'Sample ticket')
        described_class.filtered(ticket_by_keyword,
                                 {:app_id => @app_2.id, :app_name => @app_2.name},
                                 'Sample ticket')
      end
      it { should match_array([@t_2]) }
    end

  end

  protected

  def create_ticket(options = nil)
    create(:ticket, options)
  end
end
