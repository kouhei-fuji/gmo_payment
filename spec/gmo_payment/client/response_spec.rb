# coding: utf-8
require 'spec_helper'

describe GmoPayment::Client::Response, :vcr do
  subject { GmoPayment::Client::Response.new(method, args) }

  describe '#called_return_array?' do
    let(:args) { nil }
    context 'with Client#search_card' do
      let(:method) { :search_card }
      it { expect(subject.called_return_array?).to be(true) }
    end
    context 'without Client#search_card' do
      let(:method) { :entry_tran }
      it { expect(subject.called_return_array?).to be(false) }
    end
  end

  describe '#called_split_normal?' do
    let(:args) { nil }
    context 'with Client#search_trade_btc' do
      let(:method) { :search_trade_btc }
      it { expect(subject.called_split_normal?).to be(false) }
    end
    context 'without Client#search_trade_btc' do
      let(:method) { :entry_tran }
      it { expect(subject.called_split_normal?).to be(true) }
    end
  end

  let(:http_response_ok) do
    http = ::Net::HTTP.new('localhost')
    req  = ::Net::HTTP::Get.new('/ok')
    http.request(req)
  end

  describe '#http_header' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    it 'return Hash of HTTP header' do
      expect(subject.http_header).to be_a(Hash)
      expect(subject.http_header.keys).to including(/server/i)
    end
  end

  describe '#http_code' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    it 'return Integer of HTTP status code' do
      expect(subject.http_code).to be_a(Integer)
      expect(subject.http_code).to eq(200)
    end
  end

  describe '#http_message' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    it 'return String of HTTP message' do
      expect(subject.http_message).to be_a(String)
      expect(subject.http_message).to match(/ok/i)
    end
  end

  describe '#raw_body' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    it 'return String of HTTP response body as it is' do
      expect(subject.raw_body).to be_a(String)
      expect(subject.raw_body).to eq(args.body.to_s)
    end
  end

  describe '#encoded_raw_body' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    it 'return String of encoded Shift_JIS to UTF-8' do
      expect(subject.encoded_raw_body.encoding).to be(::Encoding::UTF_8)
    end
  end

  let(:http_response_ok_invalid) do
    http = ::Net::HTTP.new('localhost')
    req  = ::Net::HTTP::Get.new('/ok_invalid')
    http.request(req)
  end

  shared_examples 'URI.decode_www_form' do
    context 'with response body have only GLOSSARY keys' do
      # response body will be "AccessID=x&AccessPass=y&CardNo="
      let(:method) { nil }
      let(:args) { http_response_ok }
      it 'return predefined Array format' do
        expect(array).to be_a(Array)
        array.each do |item|
          expect(item).to be_a(Array)
          item.each_with_index do |item2, index|
            if index.even?
              expect(item2).to be_a(String)
              expect(item2).not_to match('CardNo')
            else
              expect(item2).to be_a(Array)
              expect(item2).not_to be_empty
            end
          end
        end
      end
    end
    context 'with response body have invalid parameters to split' do
      # response body will be "INVALIDTEST"
      let(:method) { nil }
      let(:args) { http_response_ok_invalid }
      it 'return empty Array' do
        expect(array).to be_empty
      end
    end
  end

  describe '#split_encoded_raw_body' do
    let(:array) { GmoPayment::Client::Response.new(method, args).split_encoded_raw_body }
    it_behaves_like 'URI.decode_www_form'
  end

  let(:http_response_ok_but) do
    http = ::Net::HTTP.new('localhost')
    req  = ::Net::HTTP::Get.new('/ok_but')
    http.request(req)
  end

  describe '#split_encoded_raw_body!' do
    let(:array) { GmoPayment::Client::Response.new(method, args).split_encoded_raw_body! }
    it_behaves_like 'URI.decode_www_form'
    context 'with response body have not only GLOSSARY keys' do
      # response body will be "A=x&B=&C=z"
      let(:method) { nil }
      let(:args) { http_response_ok_but }
      it 'returns predefined Array format without GLOSSARY keys' do
        expect(array).to be_a(Array)
        array.each do |item|
          expect(item).to be_a(Array)
          item.each_with_index do |item2, index|
            if index.even?
              expect(item2).to be_a(String)
              expect(item2).not_to match('B')
            else
              expect(item2).to be_a(Array)
              expect(item2).not_to be_empty
            end
          end
        end
      end
    end
  end

  let(:http_response_err_code) do
    http = ::Net::HTTP.new('localhost')
    req  = ::Net::HTTP::Get.new('/err_code')
    http.request(req)
  end

  describe '#prebody' do
    shared_examples 'getting Hash values Array' do
      it 'return Hash keys String and values Array' do
        expect(subject.prebody).to be_a(Hash)
        subject.prebody.each do |key, value|
          expect(key).to be_a(String)
          expect(value).to be_a(Array)
          value.each do |item|
            expect(item).to be_a(String)
          end
        end
      end
    end
    context 'with ErrCode' do
      let(:method) { nil }
      let(:args) { http_response_err_code }
      it_behaves_like 'getting Hash values Array'
    end
    context 'with #called_return_array? true' do
      let(:method) { :search_card }
      let(:args) { http_response_ok }
      it_behaves_like 'getting Hash values Array'
    end
    context 'with no ErroCode and #called_return_array? false' do
      let(:method) { nil }
      let(:args) { http_response_ok }
      it 'return Hash keys and values String' do
        expect(subject.prebody).to be_a(Hash)
        subject.prebody.each do |key, value|
          expect(key).to be_a(String)
          expect(value).to be_a(String)
        end
      end
    end
  end

  describe '#body' do
    let(:method) { nil }
    context 'with #prebody match Hash keys and GLOSSARY keys' do
      let(:args) { http_response_ok }
      it 'return Hash keys Symbol and values as it is' do
        expect(subject.body).to be_a(Hash)
        subject.body.each do |key, value|
          expect(key).to be_a(Symbol)
          expect(value).to be_a(String)
        end
      end
    end
    context 'without #prebody match Hash keys and GLOSSARY keys' do
      let(:args) { http_response_ok_but }
      it 'return Hash keys String and values as it is' do
        expect(subject.body).to be_a(Hash)
        subject.body.each do |key, value|
          expect(key).to be_a(String)
          expect(value).to be_a(String)
        end
      end
    end
  end

  describe '#http_error?' do
    let(:method) { nil }
    context 'with 2xx' do
      let(:args) { http_response_ok }
      it 'return false' do
        is_expected.not_to be_http_error
      end
    end
    context 'without 2xx' do
      let(:args) do
        http = ::Net::HTTP.new('localhost')
        req  = ::Net::HTTP::Get.new('/error_4xx')
        http.request(req)
      end
      it 'return true' do
        is_expected.to be_http_error
      end
    end
  end

  describe '#error?' do
    let(:method) { nil }
    context 'with ErrCode' do
      let(:args) { http_response_err_code }
      it 'return true' do
        is_expected.to be_error
      end
    end
    context 'without ErrCode' do
      let(:args) { http_response_ok }
      it 'return false' do
        is_expected.not_to be_error
      end
    end
  end

  describe 'GmoPayment::GLOSSARY keys to method' do
    let(:method) { nil }
    let(:args) { http_response_ok }
    # response body will be "AccessID=x&AccessPass=y&CardNo="
    it 'return #body values if #body match Hash keys and GLOSSARY keys' do
      GmoPayment::GLOSSARY.each_key do |key|
        case key
        when :access_id
          expect(subject.access_id).to eq('x')
        when :access_pass
          expect(subject.access_pass).to eq('y')
        else
          expect(subject.__send__(key)).to be(nil)
        end
      end
    end
  end

end
