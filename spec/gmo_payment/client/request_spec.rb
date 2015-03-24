# coding: utf-8
require 'spec_helper'

describe GmoPayment::Client::Request do
  before { GmoPayment.reset! }
  subject { GmoPayment::Client::Request.new(:entry_tran, args) }

  describe '#missing_items' do
    let(:args) { {} }
    it { expect(subject.missing_items).to be_a(Array) }
  end

  describe '#missing?' do
    context 'with missing items' do
      let(:args) { {} }
      it { expect(subject.missing?).to be(true) }
    end
    context 'with full items' do
      let(:args) do
        [:shop_id, :shop_pass, :order_id, :job_cd].each_with_object({}) do |item, hash|
          item == :job_cd ? hash[item] = 'CHECK' : hash[item] = 'x'
        end
      end
      it { expect(subject.missing?).to be(false) }
    end
  end

  describe '#invalid_items' do
    subject { GmoPayment::Client::Request.new(method, args).invalid_items }
    let(:method) { :entry_tran }
    let(:args) { {} }
    it { is_expected.to be_a(Hash) }
    [:entry_tran, :re_exec_tran, :change_tran].each do |called_method|
      context "with called_method is #{called_method}" do
        let(:method) { called_method }
        context 'with amount + tax <= 9,999,999' do
          let(:args) { { amount: 9_999_998, tax: 1 } }
          it { is_expected.not_to including(:amount) }
          it { is_expected.not_to including(:tax) }
        end
        context 'with amount + tax > 9,999,999' do
          let(:args) { { amount: 9_999_999, tax: 1 } }
          it { is_expected.to including(:amount) }
          it { is_expected.to including(:tax) }
        end
      end
    end
    context 'with called_method is #entry_tran_btc' do
      let(:method) { :entry_tran_btc }
      context 'with amount + tax <= 300,000' do
        let(:args) { { amount: 299_999, tax: 1 } }
        it { is_expected.not_to including(:amount) }
        it { is_expected.not_to including(:tax) }
      end
      context 'with amount + tax > 300,000' do
        let(:args) { { amount: 300_000, tax: 1 } }
        it { is_expected.to including(:amount) }
        it { is_expected.to including(:tax) }
      end
    end
  end

  describe '#invalid?' do
    context 'with invalid items' do
      let(:args) { { shop_id: 'x' * 14 } }
      it { expect(subject.invalid?).to be(true) }
    end
    context 'with all valid items' do
      let(:args) { { shop_id: 'x' * 13 } }
      it { expect(subject.invalid?).to be(false) }
    end
  end

  describe '#body' do
    let(:args) do
      [:shop_id, :shop_pass, :order_id, :job_cd].each_with_object({}) do |item, hash|
        item == :job_cd ? hash[item] = 'CHECK' : hash[item] = 'x'
      end
    end
    it { expect(subject.body).to be_a(String) }
    it { expect(subject.body).to match('ShopID=x') }
    it { expect(subject.body).to match('ShopPass=x') }
    it { expect(subject.body).to match('OrderID=x') }
    it { expect(subject.body).to match('JobCd=CHECK') }
    it 'convert invalid items (like Japanese) to application/x-www-form-urlencoded' do
      args = { client_field_1: '日本語' }
      expect(GmoPayment::Client::Request.new(:exec_tran, args)).not_to match('日本語')
    end
  end
end

describe GmoPayment::Client::Request do
  describe 'validation' do
    subject do
      request = GmoPayment::Client::Request.new(method, {})
      request.__send__('validate_valid?', key, value)
    end
    let(:method) { nil }

    describe ':access_id, :access_pass' do
      items = [:access_id, :access_pass]
      it_behaves_like 'validation of length <= n',
        items, 'x', 32
    end

    describe ':amount, :tax' do
      items = [:amount, :tax]
      it_behaves_like 'validation of number',
        items, 7
      it_behaves_like 'validation of length <= n',
        items, '1', 7
    end

    describe ':card_name' do
      items = [:card_name]
      it_behaves_like 'validation of length <= n',
        items, 'x', 10
    end

    describe ':card_no' do
      items = [:card_no]
      it_behaves_like 'validation of number',
        items, 10
      it_behaves_like 'validation of length >= n',
        items, '1', 10
      it_behaves_like 'validation of length <= n',
        items, '1', 16
    end

    describe ':card_pass' do
      items = [:card_pass]
      let(:key) { items.first }
      context 'with a-zA-Z0-9' do
        let(:value) { 'xX9' }
        it { is_expected.to be(true) }
      end
      context 'with not a-zA-Z0-9' do
        let(:value) { '!' }
        it { is_expected.to be(false) }
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 20
    end

    describe ':card_seq' do
      items = [:card_seq]
      it_behaves_like 'validation of number',
        items, 4
      it_behaves_like 'validation of length <= n',
        items, '1', 4
    end

    describe ':client_field_1, :client_field_2, :client_field_3' do
      items = [:client_field_1, :client_field_2, :client_field_3]
      context 'with not {}|^`~&<>"\'' do
        let(:value) { 'xX 9!' }
        items.each do |key|
          let(:key) { key }
          it { is_expected.to be(true) }
        end
      end
      context 'with {}|^`~&<>"\'' do
        let(:value) { %w({ } | ^ ` ~ & < > " ').sample }
        items.each do |key|
          let(:key) { key }
          it { is_expected.to be(false) }
        end
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 100
    end

    describe ':client_field_flag, :default_flag, :device_category, :seq_mode, :td_flag' do
      items = [:client_field_flag, :default_flag, :device_category, :seq_mode, :td_flag]
      it_behaves_like 'validation of value including',
        items, ['0', '1']
    end

    describe ':expire' do
      items = [:expire]
      it_behaves_like 'validation of number',
        items, 4
      let(:key) { items.first }
      context 'with length == 4' do
        let(:value) { '1' * 4 }
        it { is_expected.to be(true) }
      end
      context 'with length != 4' do
        let(:value) { '1' * [3, 5].sample }
        it { is_expected.to be(false) }
      end
    end

    describe ':holder_name' do
      items = [:holder_name]
      let(:key) { items.first }
      context 'with a-zA-Z0-9 and space' do
        let(:value) { 'xX 9' }
        it { is_expected.to be(true) }
      end
      context 'with not a-zA-Z0-9 and space' do
        let(:value) { '!' }
        it { is_expected.to be(false) }
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 50
    end

    describe ':item_code' do
      items = [:item_code]
      it_behaves_like 'validation of number',
        items, 7
      let(:key) { items.first }
      context 'with length == 7' do
        let(:value) { '1' * 7 }
        it { is_expected.to be(true) }
      end
      context 'with length != 7' do
        let(:value) { '1' * [6, 8].sample }
        it { is_expected.to be(false) }
      end
    end

    describe ':item_memo' do
      items = [:item_memo]
      it_behaves_like 'validation of length <= n',
        items, 'x', 128
    end

    describe ':item_name' do
      items = [:item_name]
      it_behaves_like 'validation of length <= n',
        items, 'x', 64
    end

    describe ':job_cd' do
      items = [:job_cd]
      context 'with Client#entry_tran' do
        let(:method) { :entry_tran }
        it_behaves_like 'validation of value including',
          items, ['CHECK', 'CAPTURE', 'AUTH', 'SAUTH']
      end
      context 'with Client#delete_tran' do
        let(:method) { :delete_tran }
        it_behaves_like 'validation of value including',
          items, ['VOID', 'RETURN', 'RETURNX']
      end
      context 'with Client#re_exec_tran' do
        let(:method) { :re_exec_tran }
        it_behaves_like 'validation of value including',
          items, ['CAPTURE', 'AUTH']
      end
      context 'with Client#change_tran' do
        let(:method) { :change_tran }
        it_behaves_like 'validation of value including',
          items, ['CAPTURE', 'AUTH', 'SAUTH']
      end
      context 'with Client#auth_to_sales or the other case' do
        let(:key) { items.first }
        let(:value) { 'SALES' }
        it { is_expected.to be(true) }
      end
    end

    describe ':member_id' do
      items = [:member_id]
      let(:key) { items.first }
      context 'with a-zA-Z0-9 _ - . @' do
        let(:value) { 'xX9_-.@' }
        it { is_expected.to be(true) }
      end
      context 'with not \w - . @' do
        let(:value) { '!' }
        it { is_expected.to be(false) }
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 60
    end

    describe ':member_name' do
      items = [:member_name]
      let(:key) { items.first }
      context 'with not {}|^`~&<>"\'' do
        let(:value) { 'xX9!' }
        it { is_expected.to be(true) }
      end
      context 'with {}|^`~&<>"\'' do
        let(:value) { %w({ } | ^ ` ~ & < > " ').sample }
        it { is_expected.to be(false) }
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 255
    end

    describe ':method' do
      items = [:method]
      it_behaves_like 'validation of value including',
        items, ['1', '2', '3', '4', '5']
    end

    describe ':order_id' do
      items = [:order_id]
      let(:key) { items.first }
      context 'with a-zA-Z0-9 and -' do
        let(:value) { 'xX-9' }
        it { is_expected.to be(true) }
      end
      context 'with not a-zA-Z0-9 and -' do
        let(:value) { '!' }
        it { is_expected.to be(false) }
      end
      it_behaves_like 'validation of length <= n',
        items, 'x', 27
    end

    describe ':pay_times' do
      items = [:pay_times]
      it_behaves_like 'validation of number',
        items, 2
      it_behaves_like 'validation of length <= n',
        items, '1', 2
    end

    describe ':pin' do
      items = [:pin]
      it_behaves_like 'validation of length <= n',
        items, 'x', 4
    end

    describe ':ret_url' do
      items = [:ret_url]
      it_behaves_like 'validation of length <= n',
        items, 'x', 256
    end

    describe ':security_code' do
      items = [:security_code]
      it_behaves_like 'validation of number',
        items, 3
      let(:key) { items.first }
      context 'with length 3 or 4' do
        [3, 4].each do |length|
          let(:value) { '1' * length }
          it { is_expected.to be(true) }
        end
      end
      context 'with not length 3 or 4' do
        [2, 5].each do |length|
          let(:value) { '1' * length }
          it { is_expected.to be(false) }
        end
      end
    end

    describe ':shop_id, :site_id' do
      items = [:shop_id, :site_id]
      it_behaves_like 'validation of length <= n',
        items, 'x', 13
    end

    describe ':shop_pass' do
      items = [:shop_pass]
      it_behaves_like 'validation of length <= n',
        items, 'x', 10
    end

    describe ':site_pass' do
      items = [:site_pass]
      it_behaves_like 'validation of length <= n',
        items, 'x', 20
    end

    describe ':td_tenant_name' do
      items = [:td_tenant_name]
      it_behaves_like 'validation of length <= n',
        items, '日', 9
    end

    describe ':timeout' do
      items = [:timeout]
      let(:key) { items.first }
      context 'with under 24 hours' do
        let(:value) { "#{24 * 60 * 60}" }
        it { is_expected.to be(true) }
      end
      context 'with over 24 hours' do
        let(:value) { "#{24 * 60 * 60 + 1}" }
        it { is_expected.to be(false) }
      end
    end

    describe 'the other cases' do
      let(:key) { :acs }
      let(:value) { 'x' }
      it { is_expected.to be(true) }
    end
  end
end
