# coding: utf-8
require 'spec_helper'

describe GmoPayment do
  describe '.setup' do
    before { GmoPayment.reset! }
    it 'setup GmoPayment::Configure variables' do
      expect {
        GmoPayment.setup { |c| c.api_endpoint = 'example.com' }
      }.to change{ GmoPayment::Configure.api_endpoint }.from(nil).to('example.com')
    end
  end

  describe '.reset!' do
    before { GmoPayment.setup { |c| c.api_endpoint = 'example.com' } }
    it 'reset GmoPayment::Configure variables' do
      expect {
        GmoPayment.reset!
      }.to change{ GmoPayment::Configure.api_endpoint }.from('example.com').to(nil)
    end
  end
end
