# coding: utf-8
require 'spec_helper'

describe GmoPayment::Client, :vcr do
  describe '#call' do
    before { GmoPayment.reset! }
    subject do
      client = GmoPayment::Client.new(api_endpoint: 'localhost', verify_mode: verify_mode)
      client.call(method, args)
    end
    context 'with missing items' do
      let(:verify_mode) { ::OpenSSL::SSL::VERIFY_PEER }
      let(:method) { :entry_tran }
      let(:args) { {} }
      it { expect { subject }.to raise_error(GmoPayment::Errors::RequestMissingItemError) }
    end
    context 'with invalid items' do
      let(:verify_mode) { ::OpenSSL::SSL::VERIFY_PEER }
      let(:method) { :entry_tran }
      let(:args) do
        {
          :shop_id   => 'x' * 14,
          :shop_pass => 'x' * 11,
          :order_id  => 'x' * 28,
          :job_cd    => 'ERROR'
        }
      end
      it { expect { subject }.to raise_error(GmoPayment::Errors::RequestInvalidItemError) }
    end
    context 'with NetworkError' do
      let(:verify_mode) { ::OpenSSL::SSL::VERIFY_PEER }
      let(:method) { :entry_tran }
      let(:args) do
        {
          :shop_id   => 'x',
          :shop_pass => 'x',
          :order_id  => 'x',
          :job_cd    => 'CHECK'
        }
      end
      it { expect { subject }.to raise_error(GmoPayment::Errors::NetworkError) }
    end
    context 'with ResponseHTTPError' do
      let(:verify_mode) { ::OpenSSL::SSL::VERIFY_NONE }
      let(:method) { :entry_tran }
      let(:args) do
        {
          :shop_id   => 'x',
          :shop_pass => 'x',
          :order_id  => 'x',
          :job_cd    => 'CHECK'
        }
      end
      it 'raise ResponseHTTPError' do
        expect { subject }.to raise_error(GmoPayment::Errors::ResponseHTTPError)
      end
    end
    context 'with ResponseHasErrCodeError' do
      let(:verify_mode) { ::OpenSSL::SSL::VERIFY_NONE }
      let(:method) { :exec_tran }
      let(:args) do
        {
          :access_id   => 'x',
          :access_pass => 'x',
          :order_id    => 'x',
          :card_no     => '1' * 10,
          :expire      => '1' * 4
        }
      end
      it 'raise ResponseHTTPError' do
        expect { subject }.to raise_error(GmoPayment::Errors::ResponseHasErrCodeError)
      end
    end
  end
end

describe GmoPayment::Client, :vcr do
  let(:card_no_n)      { ENV['GMO_TEST_CARD_NO_N'] }
  let(:card_no_n_mask) { ENV['GMO_TEST_CARD_NO_N_MASK'] }
  let(:card_no_y)      { ENV['GMO_TEST_CARD_NO_Y'] }
  let(:card_no_y_mask) { ENV['GMO_TEST_CARD_NO_Y_MASK'] }
  let(:card_pass)      { ENV['GMO_TEST_CARD_PASS'] }
  let(:card_expire)    { ENV['GMO_TEST_CARD_EXPIRE'] }

  let(:tenant_name) { 'DEVテストの店舗' }
  let(:http_accept) { '*/*' }
  let(:user_agent)  { 'Rspec' }
  let(:field_1)     { 'DEVTEST' }
  let(:field_2)     { '開発テスト' }

  before do
    GmoPayment.setup do |c|
      c.api_endpoint = ENV['GMO_TEST_API_ENDPOINT']
      c.verify_mode  = ::OpenSSL::SSL::VERIFY_PEER
      c.site_id      = ENV['GMO_TEST_SITE_ID']
      c.site_pass    = ENV['GMO_TEST_SITE_PASS']
      c.shop_id      = ENV['GMO_TEST_SHOP_ID']
      c.shop_pass    = ENV['GMO_TEST_SHOP_PASS']
    end
  end
  let(:client) { GmoPayment::Client.new }

  describe '#entry_tran' do
    let(:call_method) { '#entry_tran' }
    let(:order_id) { 'T-1' }
    it 'return 2 items' do
      args = {
        :order_id => order_id,
        :job_cd   => 'CHECK'
      }
      response = client.entry_tran(args)
      expect(response.access_id).not_to be(nil)
      expect(response.access_pass).not_to be(nil)
    end
  end

  describe '#exec_tran' do
    let(:call_method) { '#exec_tran' }
    let(:order_id) { 'T-2' }
    it 'return 12 items' do
      args1 = {
        :order_id => order_id,
        :job_cd   => 'CAPTURE',
        :amount   => 1
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      response = client.exec_tran(args2)
      expect(response.acs).to eq('0')
      expect(response.order_id).to eq(order_id)
      expect(response.forward).not_to be(nil)
      expect(response.method).to eq('1')
      expect(response.pay_times).to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
      expect(response.check_string).not_to be(nil)
      expect(response.client_field_1).to eq(field_1)
      expect(response.client_field_2).to eq(field_2)
      expect(response.client_field_3).to eq(call_method)
    end
  end

  describe '#exec_tran_3d' do
    let(:call_method) { '#exec_tran_3d' }
    let(:order_id) { 'T-3' }
    it 'return 4 items' do
      args1 = {
        :order_id       => order_id,
        :job_cd         => 'AUTH',
        :amount         => 1,
        :tax            => 1,
        :td_flag        => 1,
        :td_tenant_name => tenant_name
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id       => res.access_id,
        :access_pass     => res.access_pass,
        :order_id        => order_id,
        :card_no         => card_no_y,
        :expire          => card_expire,
        :http_accept     => http_accept,
        :http_user_agent => user_agent,
        :method          => 2,
        :pay_times       => 2,
        :client_field_1  => field_1,
        :client_field_2  => field_2,
        :client_field_3  => call_method
      }
      response = client.exec_tran_3d(args2)
      expect(response.acs).to eq('1')
      expect(response.acs_url).not_to be(nil)
      expect(response.pa_req).not_to be(nil)
      expect(response.md).not_to be(nil)
    end
  end

  describe '#secure_tran' do
    let(:call_method) { '#secure_tran' }
    let(:order_id) { 'T-4' }
    it 'return 11 items' do
      args1 = {
        :order_id       => order_id,
        :job_cd         => 'AUTH',
        :amount         => 1,
        :tax            => 1,
        :td_flag        => 1,
        :td_tenant_name => tenant_name
      }
      res1 = client.entry_tran(args1)
      args2 = {
        :access_id       => res1.access_id,
        :access_pass     => res1.access_pass,
        :order_id        => order_id,
        :card_no         => card_no_y,
        :expire          => card_expire,
        :http_accept     => http_accept,
        :http_user_agent => user_agent,
        :method          => 3,
        :pay_times       => 1,
        :client_field_1  => field_1,
        :client_field_2  => field_2,
        :client_field_3  => call_method
      }
      client.exec_tran_3d(args2)
      # After the operation in the browser, "MD" and "PaRes" will be returned.
      args3 = {
        :md     => "365441d388c41ddae535c24c6cebdad4",
        :pa_res => "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\r\n"
      }
      response = client.secure_tran(args3)
      expect(response.order_id).to eq(order_id)
      expect(response.forward).not_to be(nil)
      expect(response.method).to eq('3')
      expect(response.pay_times).to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
      expect(response.check_string).not_to be(nil)
      expect(response.client_field_1).to eq(field_1)
      expect(response.client_field_2).to eq(field_2)
      expect(response.client_field_3).to eq(call_method)
    end
  end

  describe '#save_member' do
    let(:call_method) { '#save_member' }
    let(:member_id) { 'T-M1' }
    it 'return 1 items' do
      args = {
        :member_id => member_id
      }
      response = client.save_member(args)
      expect(response.member_id).to eq(member_id)
    end
  end

  describe '#update_member' do
    let(:call_method) { '#update_member' }
    let(:member_id) { 'T-M2' }
    it 'return 1 items' do
      member_name_old = 'old_name'
      member_name_new = 'new_name'
      args1 = {
        :member_id   => member_id,
        :member_name => member_name_old
      }
      client.save_member(args1)
      args2 = {
        :member_id   => member_id,
        :member_name => member_name_new
      }
      response = client.update_member(args2)
      expect(response.member_id).to eq(member_id)
    end
  end

  describe '#delete_member' do
    let(:call_method) { '#delete_member' }
    let(:member_id) { 'T-M3' }
    it 'return 1 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id
      }
      response = client.delete_member(args2)
      expect(response.member_id).to eq(member_id)
    end
  end

  describe '#search_member' do
    let(:call_method) { '#search_member' }
    let(:member_id) { 'T-M4' }
    it 'return 3 items' do
      member_name = 'member_name'
      args1 = {
        :member_id   => member_id,
        :member_name => member_name
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id
      }
      response = client.search_member(args2)
      expect(response.member_id).to eq(member_id)
      expect(response.member_name).to eq(member_name)
      expect(response.delete_flag).to eq('0')
    end
  end

  describe '#save_card' do
    let(:call_method) { '#save_card' }
    let(:member_id) { 'T-M5' }
    it 'return 3 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      response = client.save_card(args2)
      expect(response.card_seq).to eq('0') | eq('1') | eq('2') | eq('3') | eq('4')
      expect(response.card_no).to eq(card_no_n_mask)
      expect(response.forward).not_to be(nil)
    end
  end

  describe '#update_card' do
    let(:call_method) { '#update_card' }
    let(:member_id) { 'T-M6' }
    it 'return 3 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      res = client.save_card(args2)
      args3 = {
        :member_id => member_id,
        :card_seq  => res.card_seq,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      response = client.update_card(args3)
      expect(response.card_seq).to eq('0') | eq('1') | eq('2') | eq('3') | eq('4')
      expect(response.card_no).to eq(card_no_n_mask)
      expect(response.forward).not_to be(nil)
    end
  end

  describe '#delete_card' do
    let(:call_method) { '#delete_card' }
    let(:member_id) { 'T-M7' }
    it 'return 1 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      res = client.save_card(args2)
      args3 = {
        :member_id => member_id,
        :card_seq  => res.card_seq
      }
      response = client.delete_card(args3)
      expect(response.card_seq).to eq(res.card_seq)
    end
  end

  describe '#search_card' do
    let(:call_method) { '#search_card' }
    let(:member_id) { 'T-M8' }
    it 'return 7 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      client.save_card(args2)
      args3 = {
        :member_id => member_id,
        :seq_mode  => 0
      }
      response = client.search_card(args3)
      expect(response.card_seq).to eq(['0'])
      expect(response.default_flag).to eq(['0'])
      expect(response.card_name).to be(nil)
      expect(response.card_no).to eq(["#{card_no_n_mask}"])
      expect(response.expire).to eq(["#{card_expire}"])
      expect(response.holder_name).to be(nil)
      expect(response.delete_flag).to eq(['0'])
    end
  end

  describe '#exec_tran_member' do
    let(:call_method) { '#exec_tran_member' }
    let(:order_id) { 'T-5' }
    let(:member_id) { 'T-M9' }
    it 'return 12 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_n,
        :expire    => card_expire
      }
      res1 = client.save_card(args2)
      args3 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => 1
      }
      res2 = client.entry_tran(args3)
      args4 = {
        :access_id      => res2.access_id,
        :access_pass    => res2.access_pass,
        :order_id       => order_id,
        :member_id      => member_id,
        :card_seq       => res1.card_seq,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      response = client.exec_tran_member(args4)
      expect(response.acs).to eq('0')
      expect(response.order_id).to eq(order_id)
      expect(response.forward).not_to be(nil)
      expect(response.method).to eq('1')
      expect(response.pay_times).to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
      expect(response.check_string).not_to be(nil)
      expect(response.client_field_1).to eq(field_1)
      expect(response.client_field_2).to eq(field_2)
      expect(response.client_field_3).to eq(call_method)
    end
  end

  describe '#exec_tran_member_3d' do
    let(:call_method) { '#exec_tran_member_3d' }
    let(:order_id) { 'T-6' }
    let(:member_id) { 'T-M10' }
    it 'return 4 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :member_id => member_id,
        :card_no   => card_no_y,
        :expire    => card_expire
      }
      res1 = client.save_card(args2)
      args3 = {
        :order_id       => order_id,
        :job_cd         => 'AUTH',
        :amount         => 1,
        :td_flag        => 1,
        :td_tenant_name => tenant_name
      }
      res2 = client.entry_tran(args3)
      args4 = {
        :access_id       => res2.access_id,
        :access_pass     => res2.access_pass,
        :order_id        => order_id,
        :member_id       => member_id,
        :card_seq        => res1.card_seq,
        :http_accept     => http_accept,
        :http_user_agent => user_agent,
        :method          => 1,
        :client_field_1  => field_1,
        :client_field_2  => field_2,
        :client_field_3  => call_method
      }
      response = client.exec_tran_member_3d(args4)
      expect(response.acs).to eq('1')
      expect(response.acs_url).not_to be(nil)
      expect(response.pa_req).not_to be(nil)
      expect(response.md).not_to be(nil)
    end
  end

  describe '#delete_tran' do
    let(:call_method) { '#delete_tran' }
    let(:order_id) { 'T-7' }
    it 'return 6 items' do
      args1 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => 1
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      client.exec_tran(args2)
      args3 = {
        :access_id   => res.access_id,
        :access_pass => res.access_pass,
        :job_cd      => 'VOID'
      }
      response = client.delete_tran(args3)
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.forward).not_to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
    end
  end

  describe '#re_exec_tran' do
    let(:call_method) { '#re_exec_tran' }
    let(:order_id) { 'T-8' }
    it 'return 6 items' do
      args1 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => 1
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      client.exec_tran(args2)
      args3 = {
        :access_id   => res.access_id,
        :access_pass => res.access_pass,
        :job_cd      => 'VOID'
      }
      client.delete_tran(args3)
      args4 = {
        :access_id   => res.access_id,
        :access_pass => res.access_pass,
        :job_cd      => 'AUTH',
        :amount      => 1,
        :method      => 1
      }
      response = client.re_exec_tran(args4)
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.forward).not_to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
    end
  end

  describe '#auth_to_sales' do
    let(:call_method) { '#auth_to_sales' }
    let(:order_id) { 'T-9' }
    it 'return 6 items' do
      amount = 1
      args1 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => amount
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      client.exec_tran(args2)
      args3 = {
        :access_id   => res.access_id,
        :access_pass => res.access_pass,
        :amount      => amount
      }
      response = client.auth_to_sales(args3)
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.forward).not_to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
    end
  end

  describe '#change_tran' do
    let(:call_method) { '#change_tran' }
    let(:order_id) { 'T-10' }
    it 'return 6 items' do
      amount_old = 1
      amount_new = 2
      args1 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => amount_old
      }
      res = client.entry_tran(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      client.exec_tran(args2)
      args3 = {
        :access_id   => res.access_id,
        :access_pass => res.access_pass,
        :job_cd      => 'AUTH',
        :amount      => amount_new
      }
      response = client.change_tran(args3)
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.forward).not_to be(nil)
      expect(response.approve).not_to be(nil)
      expect(response.tran_id).not_to be(nil)
      expect(response.tran_date).not_to be(nil)
    end
  end

  describe '#search_trade' do
    let(:call_method) { '#search_trade' }
    let(:order_id) { 'T-11' }
    it 'return 21 items' do
      args1 = {
        :order_id => order_id,
        :job_cd   => 'CHECK'
      }
      res = client.entry_tran(args1)
      args2 = {
        :order_id => order_id
      }
      response = client.search_trade(args2)
      expect(response.order_id).to eq(order_id)
      expect(response.status).to eq('UNPROCESSED')
      expect(response.process_date).not_to be(nil)
      expect(response.job_cd).to eq('CHECK')
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.item_code).not_to be(nil)
      expect(response.amount).to eq('0')
      expect(response.tax).to eq('0')
      expect(response.site_id).to be(nil)
      expect(response.member_id).to be(nil)
      expect(response.card_no).to be(nil)
      expect(response.expire).to be(nil)
      expect(response.method).to be(nil)
      expect(response.pay_times).to be(nil)
      expect(response.forward).to be(nil)
      expect(response.tran_id).to be(nil)
      expect(response.approve).to be(nil)
      expect(response.client_field_1).to be(nil)
      expect(response.client_field_2).to be(nil)
      expect(response.client_field_3).to be(nil)
    end
  end

  describe '#save_traded_card' do
    let(:call_method) { '#save_traded_card' }
    let(:order_id) { 'T-12' }
    let(:member_id) { 'T-M11' }
    it 'return 3 items' do
      args1 = {
        :member_id => member_id
      }
      client.save_member(args1)
      args2 = {
        :order_id => order_id,
        :job_cd   => 'AUTH',
        :amount   => 1
      }
      res1 = client.entry_tran(args2)
      args3 = {
        :access_id      => res1.access_id,
        :access_pass    => res1.access_pass,
        :order_id       => order_id,
        :card_no        => card_no_n,
        :expire         => card_expire,
        :method         => 1,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      res2 = client.exec_tran(args3)
      args4 = {
        :order_id  => order_id,
        :member_id => member_id
      }
      response = client.save_traded_card(args4)
      expect(response.card_seq).to eq('0') | eq('1') | eq('2') | eq('3') | eq('4')
      expect(response.card_no).to eq(card_no_n_mask)
      expect(response.forward).to eq(res2.forward)
    end
  end

  describe '#entry_tran_btc' do
    let(:call_method) { '#entry_tran_btc' }
    let(:order_id) { 'T-13' }
    it 'return 2 items' do
      args = {
        :order_id => order_id,
        :amount   => 1
      }
      response = client.entry_tran_btc(args)
      expect(response.access_id).not_to be(nil)
      expect(response.access_pass).not_to be(nil)
    end
  end

  describe '#exec_tran_btc' do
    let(:call_method) { '#exec_tran_btc' }
    let(:order_id) { 'T-14' }
    it 'return 3 items' do
      args1 = {
        :order_id => order_id,
        :amount   => 1
      }
      res = client.entry_tran_btc(args1)
      args2 = {
        :access_id      => res.access_id,
        :access_pass    => res.access_pass,
        :order_id       => order_id,
        :ret_url        => 'https://localhost/recieve?query1=Test01&query2=DEV環境のテストです。',
        :item_name      => 'DEVテストの商品',
        :item_memo      => 'これはDevelopment環境のテスト用の商品です。',
        :timeout        => 60,
        :client_field_1 => field_1,
        :client_field_2 => field_2,
        :client_field_3 => call_method
      }
      response = client.exec_tran_btc(args2)
      expect(response.access_id).to eq(res.access_id)
      expect(response.token).not_to be(nil)
      expect(response.start_url).not_to be(nil)
    end
  end

  describe '#search_trade_btc' do
    let(:call_method) { '#search_trade_btc' }
    let(:order_id) { 'T-15' }
    it 'return 11 items' do
      args1 = {
        :order_id => order_id,
        :amount   => 1
      }
      res = client.entry_tran_btc(args1)
      args2 = {
        :order_id => order_id
      }
      response = client.search_trade_btc(args2)
      expect(response.status).to eq('UNPROCESSED')
      expect(response.process_date).not_to be(nil)
      expect(response.access_id).to eq(res.access_id)
      expect(response.access_pass).to eq(res.access_pass)
      expect(response.amount).to eq('1')
      expect(response.tax).to eq('0')
      expect(response.currency).to be(nil)
      expect(response.client_field_1).to be(nil)
      expect(response.client_field_2).to be(nil)
      expect(response.client_field_3).to be(nil)
      expect(response.pay_type).not_to be(nil)
    end
  end

end
