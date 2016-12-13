require 'spec_helper'
require 'survey_gizmo/configuration'

describe SurveyGizmo::Configuration do
  before(:each) do
    @client = SurveyGizmo::Client.new
    @client.configure do |config|
      config.api_token = 'token'
      config.api_token_secret = 'doken'
    end
  end

  after(:each) do
    @client.reset!
  end

  it 'should allow changing user and pass' do
    # preload connection to verify that memoization is purged
    @client.send(:connection)

    @client.configure do |config|
      config.api_token = 'slimthug'
      config.api_token_secret = 'fourfourz'
    end

    expect(@client.send(:connection).params).to eq('api_token' => 'slimthug', 'api_token_secret' => 'fourfourz')
  end

  describe '#region=' do
    it 'should set US region by default' do
      @client.configure
      expect(@client.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(@client.configuration.api_time_zone).to eq('Eastern Time (US & Canada)')
    end

    it 'should set US region with :us symbol specified' do
      @client.configure do |config|
        config.region = :us
      end

      expect(@client.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(@client.configuration.api_time_zone).to eq('Eastern Time (US & Canada)')
    end

    it 'should set EU region with :eu symbol specified' do
      @client.configure do |config|
        config.region = :eu
      end

      expect(@client.configuration.api_url).to eq('https://restapi.surveygizmo.eu')
      expect(@client.configuration.api_time_zone).to eq('Berlin')
    end

    it 'should fail with an unavailable region' do
      expect {
        @client.configure do |config|
          config.region = :cz
        end
      }.to raise_error
    end

  end
end
