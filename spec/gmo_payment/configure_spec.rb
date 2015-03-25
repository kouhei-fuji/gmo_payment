# coding: utf-8
require 'spec_helper'

describe GmoPayment::Configure do
  let(:configure) { GmoPayment::Configure }

  describe '.setup' do
    before { configure.reset! }
    it 'set variables' do
      expect {
        configure.setup { |c| c.api_endpoint = 'example.com' }
      }.to change { configure.api_endpoint }.from(nil).to('example.com')
    end
  end
  describe '.reset!' do
    before { configure.setup { |c| c.api_endpoint = 'example.com' } }
    it 'reset variables' do
      expect {
        configure.reset!
      }.to change { configure.api_endpoint }.from('example.com').to(nil)
    end
  end

  context 'with default' do
    before { configure.reset! }
    describe '.api_endpoint' do
      it { expect(configure.api_endpoint).to be(nil) }
    end
    describe '.proxy' do
      it { expect(configure.proxy).to be(nil) }
    end
    describe '.verify_mode' do
      it { expect(configure.verify_mode).to be(nil) }
    end
    describe '.error_list' do
      it { expect(configure.error_list).to be(nil) }
    end
    describe '.site_id' do
      it { expect(configure.site_id).to be(nil) }
    end
    describe '.site_pass' do
      it { expect(configure.site_pass).to be(nil) }
    end
    describe '.shop_id' do
      it { expect(configure.shop_id).to be(nil) }
    end
    describe '.shop_pass' do
      it { expect(configure.shop_pass).to be(nil) }
    end
  end

  context 'after .setup' do
    before do
      configure.setup do |c|
        c.api_endpoint = 'example.com'
        c.proxy        = 'https://user:password@proxy.com:443/'
        c.verify_mode  = 1
        c.error_list   = 'path/to/file.yml'
        c.site_id      = 'GMO_SITE_ID'
        c.site_pass    = 'GMO_SITE_PASS'
        c.shop_id      = 'GMO_SHOP_ID'
        c.shop_pass    = 'GMO_SHOP_PASS'
      end
    end
    describe '.api_endpoint' do
      it { expect(configure.api_endpoint).to eq('example.com') }
    end
    describe '.proxy' do
      it { expect(configure.proxy).to eq('https://user:password@proxy.com:443/') }
    end
    describe '.verify_mode' do
      it { expect(configure.verify_mode).to eq(1) }
    end
    describe '.error_list' do
      it { expect(configure.error_list).to eq('path/to/file.yml') }
    end
    describe '.site_id' do
      it { expect(configure.site_id).to eq('GMO_SITE_ID') }
    end
    describe '.site_pass' do
      it { expect(configure.site_pass).to eq('GMO_SITE_PASS') }
    end
    describe '.shop_id' do
      it { expect(configure.shop_id).to eq('GMO_SHOP_ID') }
    end
    describe '.shop_pass' do
      it { expect(configure.shop_pass).to eq('GMO_SHOP_PASS') }
    end
  end
end
