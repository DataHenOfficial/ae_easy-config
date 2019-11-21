require 'test_helper'

describe 'version' do
  it 'should have a version' do
    refute_nil DhEasy::Config::VERSION
  end
end
