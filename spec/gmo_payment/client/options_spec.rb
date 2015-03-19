# coding: utf-8
require 'spec_helper'

describe GmoPayment::Client::Options do
  context 'with default' do
    before { GmoPayment::Configure.reset! }
    describe '#api_endpoint' do
      subject { GmoPayment::Client::Options.new.api_endpoint }
      before { ENV['GMO_API_ENDPOINT'] = nil }
      it { is_expected.to be(nil) }
      it "with ENV['GMO_API_ENDPOINT'] return it" do
        ENV['GMO_API_ENDPOINT'] = 'test'
        is_expected.to eq('test')
      end
    end
    describe '#proxy' do
      subject { GmoPayment::Client::Options.new.proxy }
      it { is_expected.to be_a(::URI::Generic) }
      it { is_expected.to respond_to(:host) }
      it { is_expected.to respond_to(:port) }
      it { is_expected.to respond_to(:user) }
      it { is_expected.to respond_to(:password) }
    end
    describe '#verify_mode' do
      subject { GmoPayment::Client::Options.new.verify_mode }
      it { is_expected.to be(::OpenSSL::SSL::VERIFY_PEER) }
    end
  end

  context 'after GmoPayment::Configure.setup' do
    before do
      GmoPayment::Configure.setup do |c|
        c.api_endpoint  = 'example.com'
        c.proxy         = 'https://user:password@proxy.com:443/'
        c.verify_mode   = ::OpenSSL::SSL::VERIFY_NONE
      end
    end
    describe '#api_endpoint' do
      subject { GmoPayment::Client::Options.new.api_endpoint }
      before { ENV['GMO_API_ENDPOINT'] = nil }
      it { is_expected.to eq('example.com') }
      it "with ENV['GMO_API_ENDPOINT'] return setup value" do
        ENV['GMO_API_ENDPOINT'] = 'test'
        is_expected.to eq('example.com')
      end
    end
    describe '#proxy' do
      subject { GmoPayment::Client::Options.new.proxy }
      it { is_expected.to be_a(::URI::HTTP) }
      it '#host return setup and URI.parse value' do
        expect(subject.host).to eq('proxy.com')
      end
      it '#port return setup and URI.parse value' do
        expect(subject.port).to eq(443)
      end
      it '#user return setup and URI.parse value' do
        expect(subject.user).to eq('user')
      end
      it '#password return setup and URI.parse value' do
        expect(subject.password).to eq('password')
      end
    end
    describe '#verify_mode' do
      subject { GmoPayment::Client::Options.new.verify_mode }
      it { is_expected.to be(::OpenSSL::SSL::VERIFY_NONE) }
    end
  end

  context 'after GmoPayment::Configure.setup and with argument' do
    before do
      GmoPayment::Configure.setup do |c|
        c.api_endpoint  = 'example.com'
        c.proxy         = 'https://user:password@proxy.com:443/'
        c.verify_mode   = ::OpenSSL::SSL::VERIFY_NONE
      end
    end
    describe '#api_endpoint' do
      subject { GmoPayment::Client::Options.new(api_endpoint: 'test.com').api_endpoint }
      it { is_expected.to eq('test.com') }
      before { ENV['GMO_API_ENDPOINT'] = nil }
      it "with ENV['GMO_API_ENDPOINT'] and setup value return initialize argument" do
        ENV['GMO_API_ENDPOINT'] = 'test'
        is_expected.to eq('test.com')
      end
    end
    describe '#proxy' do
      subject { GmoPayment::Client::Options.new(proxy: 'http://u:p@t.com:8080/').proxy }
      it { is_expected.to be_a(::URI::HTTP) }
      it '#host return initialize and URI.parse argument' do
        expect(subject.host).to eq('t.com')
      end
      it '#port return initialize and URI.parse argument' do
        expect(subject.port).to eq(8080)
      end
      it '#user return initialize and URI.parse argument' do
        expect(subject.user).to eq('u')
      end
      it '#password return initialize and URI.parse argument' do
        expect(subject.password).to eq('p')
      end
    end
    describe '#verify_mode' do
      subject { GmoPayment::Client::Options.new(verify_mode: 'a').verify_mode }
      it { is_expected.to eq('a') }
    end
  end
end
