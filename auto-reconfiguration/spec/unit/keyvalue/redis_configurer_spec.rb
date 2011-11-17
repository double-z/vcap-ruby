require 'spec_helper'
require 'redis'
require 'cfautoconfig/keyvalue/redis_configurer'

describe 'AutoReconfiguration::Redis' do

  before(:each) do
    ENV['VCAP_SERVICES'] = '{"redis-2.2":[{"name": "redis-1","label": "redis-2.2",' +
      '"plan": "free", "credentials": {"node_id": "redis_node_8","hostname": ' +
      '"10.20.30.40","port": 1234,"password": "mypass","name": "r1"}}]}'
    load 'cfruntime/properties.rb'
  end

  it 'auto-configures Redis on initialize with host and port' do
    redis = Redis.new(:host => '127.0.0.1',
                                :port => '6321',
                                :password => 'mypw')
    redis.client.host.should == '10.20.30.40'
    redis.client.port.should ==  1234
    redis.client.password.should == 'mypass'
  end

  it 'auto-configures Redis on initialize with path' do
    redis = Redis.new(:path => '127.0.0.1:6321',
                                :password => 'mypw')
    redis.client.path.should == '10.20.30.40:1234'
    redis.client.password.should == 'mypass'
  end

  it 'does not auto-configure Redis if VCAP_SERVICES not set' do
    ENV['VCAP_SERVICES'] = nil
    load 'cfruntime/properties.rb'
    redis = Redis.new(:host => '127.0.0.1',
                                 :port => '6321',
                                 :password => 'mypw')
    redis.client.host.should == '127.0.0.1'
    redis.client.port.should ==  6321
    redis.client.password.should == 'mypw'
  end

  it 'disables Redis auto-reconfig if DISABLE_AUTO_CONFIG includes redis' do
    ENV['DISABLE_AUTO_CONFIG'] = "redis:mongodb"
    load 'cfautoconfig/keyvalue/redis_configurer.rb'
    redis = Redis.new(:host => '127.0.0.1',
                                :port => '6321',
                                :password => 'mypw')
    redis.client.host.should == '127.0.0.1'
    redis.client.port.should ==  6321
    redis.client.password.should == 'mypw'
  end
end