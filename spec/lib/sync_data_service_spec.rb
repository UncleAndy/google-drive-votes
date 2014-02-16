# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SyncDataService do
  describe ".process_input" do
    context "for NEW_MEMBER event" do
      before(:each) do
        @data = {
          :idhash => '1',
          :doc_key => '2',
          :doc_key_type => 'GOOGLEDOC'
          }
        @sq = FactoryGirl.create(:sync_queue, :status => 'new', :cmd => 'NEW_MEMBER', :data => @data.to_json)
      end

      it 'should be create new member' do
        lambda do
          SyncDataService.process_input
        end.should change(TrustNetMember, :count).by(1)
        member = TrustNetMember.order(:id).last
        member.idhash.should eq(@data[:idhash])
        member.doc_key.should eq(@data[:doc_key])
        member.doc_key_type.should eq(@data[:doc_key_type])
      end

      it 'should set for queue status to "out"' do
        SyncDataService.process_input
        @sq.reload
        @sq.status.should eq('out')
      end
    end

    context "for SERVERS event" do
      before(:each) do
        @data = {
          :servers => [
              'http://server1/',
              'http://server2/',
              'http://server3/'
            ]
          }
        @sq = FactoryGirl.create(:sync_queue, :status => 'new', :cmd => 'SERVERS', :data => @data.to_json)
      end

      it 'should be create new servers' do
        lambda do
          SyncDataService.process_input
        end.should change(Server, :count).by(3)
      end

      it 'should set for queue status to "out"' do
        SyncDataService.process_input
        @sq.reload
        @sq.status.should eq('out')
      end
    end
  end
end
