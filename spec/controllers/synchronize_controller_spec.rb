# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SynchronizeController do
  describe "#create" do
    before(:each) do
      request.class_eval do
        def header=(s)
          @env = s
          ActionDispatch::Http::Headers.new(@env)
        end
      end
      
      @secret = '321'
      FactoryGirl.create(:sync_host, :url => 'http://test/synchronize', :secret => @secret, :host_id => '123', :active => true)
    end
    
    context "для запроса на синхронизацию участников" do
      before(:each) do
        query_id = Guid.new.hexdigest
        data = {
          :idhash => '1',
          :doc_key => '2',
          :nick => 'testnick'
        }
        @json = {
          :query_id => query_id,
          :cmd => 'NEW_MEMBER',
          :data => data
          }.to_json
        data_str = {:query_id => query_id, :cmd => 'NEW_MEMBER', :data => data}.to_json
        check_string = "#{@secret}:#{data_str}"
        @check_sum = Digest::SHA256.hexdigest(check_string)
        request.header= (request.env.merge({'X-Host-Id' =>  '123', 'X-Checksum' => @check_sum}))
      end
      
      it 'должен вернуть ОК' do
        request.env['RAW_POST_DATA'] = @json
        post :create
        response.body.should eq('OK')
      end

      it 'должен создать запись в SyncQueue' do
        lambda do
          request.env['RAW_POST_DATA'] = @json
          post :create
        end.should change(SyncQueue, :count).by(1)
      end
    end

    context "для запроса на синхронизацию списка серверов" do
      before(:each) do
        query_id = Guid.new.hexdigest
        data = {
          :servers => ['http://server1/', 'http://server2/', 'http://server3/']
        }
        @json = {
          :query_id => query_id,
          :cmd => 'SERVERS',
          :data => data
          }.to_json
        data_str = {:query_id => query_id, :cmd => 'SERVERS', :data => data}.to_json
        check_string = "#{@secret}:#{data_str}"
        @check_sum = Digest::SHA256.hexdigest(check_string)
        request.header= (request.env.merge({'X-Host-Id' =>  '123', 'X-Checksum' => @check_sum}))
      end

      it 'должен вернуть ОК' do
        request.env['RAW_POST_DATA'] = @json
        post :create
        response.body.should eq('OK')
      end

      it 'должен создать запись в SyncQueue' do
        lambda do
          request.env['RAW_POST_DATA'] = @json
          post :create
        end.should change(SyncQueue, :count).by(1)
      end
    end
  end
end
