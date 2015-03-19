# coding: utf-8
require 'spec_helper'

describe GmoPayment::Errors do
  it { expect(GmoPayment::Errors.new).to be_a(::StandardError) }

  let(:basic_error) { GmoPayment::Errors }
  describe 'NetworkError' do
    subject { GmoPayment::Errors::NetworkError.new('a', 'b', 'c') }
    it { is_expected.to be_a(basic_error) }
    it { is_expected.to respond_to(:called_method) }
    it { is_expected.to respond_to(:request) }
    it '#called_method return first argument as it is' do
      expect(subject.called_method).to eq('a')
    end
    it '#request return second argument as it is' do
      expect(subject.request).to eq('b')
    end
    it '#message return third argument as it is' do
      expect(subject.message).to eq('c')
    end
  end

  describe 'RequestMissingItemError' do
    subject { GmoPayment::Errors::RequestMissingItemError.new('a', ['b', 'c']) }
    it { is_expected.to be_a(basic_error) }
    it { is_expected.to respond_to(:called_method) }
    it { is_expected.to respond_to(:items) }
    it '#called_method return first argument as it is' do
      expect(subject.called_method).to eq('a')
    end
    it '#items return second argument as it is' do
      expect(subject.items).to eq(['b', 'c'])
    end
    it '#message return second argument join ", "' do
      expect(subject.message).to match('b, c')
    end
  end

  describe 'RequestInvalidItemError' do
    subject { GmoPayment::Errors::RequestInvalidItemError.new('a', { b: 'c', d: 'e' }) }
    it { is_expected.to be_a(basic_error) }
    it { is_expected.to respond_to(:called_method) }
    it { is_expected.to respond_to(:items) }
    it '#called_method return first argument as it is' do
      expect(subject.called_method).to eq('a')
    end
    it '#items return second argument as it is' do
      expect(subject.items).to eq({ b: 'c', d: 'e' })
    end
    it '#message return second argument join ":key (v)" and ","' do
      expect(subject.message).to match(':b (c), :d (e)')
    end
  end

  describe 'ResponseHTTPError' do
    subject { GmoPayment::Errors::ResponseHTTPError.new('a', 'b') }
    it { is_expected.to be_a(basic_error) }
    it { is_expected.to respond_to(:called_method) }
    it { is_expected.to respond_to(:request) }
    it '#called_method return first argument as it is' do
      expect(subject.called_method).to eq('a')
    end
    it '#request return second argument as it is' do
      expect(subject.request).to eq('b')
    end
    it '#message return announce "called from {first argument}"' do
      expect(subject.message).to match('called from `a\'')
      expect(subject.message).to match('not 2xx')
    end
  end

  describe 'ResponseHasErrCodeError' do
    subject { GmoPayment::Errors::ResponseHasErrCodeError.new('a', 'b') }
    it { is_expected.to be_a(basic_error) }
    it { is_expected.to respond_to(:called_method) }
    it { is_expected.to respond_to(:response) }
    it '#called_method return first argument as it is' do
      expect(subject.called_method).to eq('a')
    end
    it '#response return second argument as it is' do
      expect(subject.response).to eq('b')
    end
    it '#message return announce "called from {first argument}"' do
      expect(subject.message).to match('called from `a\'')
      expect(subject.message).to match('ErrCode')
    end
  end
end
