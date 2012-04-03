require 'spec_helper'

module Mandrill

  describe "authorization_url" do
    it "should require an app_id and redirect_url" do
      expect {Mandrill::API.authorization_url}.should raise_error(ArgumentError)
      expect {Mandrill::API.authorization_url(@app_id)}.should raise_error(ArgumentError)
      expect {Mandrill::API.authorization_url(@app_id, @callback_url)}.should_not raise_error(ArgumentError)
    end

    it "should generate an authorization URL" do
      @callback_url = 'https://test.com/callback'
      url = Mandrill::API.authorization_url(@app_id, @callback_url)
      url.should eq("#{Mandrill::API::AUTH_URL}?id=#{@app_id}&redirect_url=#{URI.escape(@callback_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}")
    end
  end

  describe API do
    API_URL = "#{Mandrill::API::API_URL}/#{Mandrill::API::API_VERSION}"

    describe "initializing" do
      it "requires an API key" do
        expect {Mandrill::API.new}.should raise_error(ArgumentError)
      end

      it "also accepts config options" do
        expect {Mandrill::API.new(@api_key, {:format => 'xml'})}.should_not raise_error(ArgumentError)
      end
    end

    describe "calling the API" do
      before(:each) do
        @m = Mandrill::API.new(@api_key)
      end

      it "should call the correct API method" do
        FakeWeb.register_uri(:post, "#{API_URL}/users/info.json", :body => '{"username": "example"}')
        @m.users(:info)['username'].should eq('example')
      end

      describe "and getting a response" do
        before(:each) do
          FakeWeb.register_uri(:post, "#{API_URL}/users/ping.json", :body => "\"PONG!\"")
        end

        it "should return 'PONG!' when pinging successfully" do
          @m.users(:ping).should eq("PONG!")
        end

        it "should respond_to? correctly" do
          FakeWeb.register_uri(:post, "#{API_URL}/users/nomethod.json", :status => [500, "Internal Server Eror"])
          @m.respond_to?('users', :ping).should eq(true)
          @m.respond_to?('users', :nomethod).should eq(false)
        end
        
        it "should raise a Mandrill::API error when needed" do
          FakeWeb.register_uri(:post, "#{API_URL}/tags/info.json", :status => [500, "Internal Server Eror"], :body => @error)
          expect {@m.tags(:info)}.should raise_error(Mandrill::API::Error)
        end
      end
    end
  end
end