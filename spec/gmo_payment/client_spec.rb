# coding: utf-8
require 'spec_helper'

is_cassette_available = -> { VCR.current_cassette.originally_recorded_at }
uuid = -> (name:, index: 0) { YAML.load_file(VCR.current_cassette.file)['http_interactions'][index]['request']['body']['string'].match(/#{GmoPayment::GLOSSARY[name]}=([^&]+)/)[1] }

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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
        :md     => "7aacaf1ed56f6de279f1dbdf71c1caf2",
        :pa_res => "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"
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id, index: 2) : SecureRandom.hex(27/2) }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id, index: 2) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:member_id) { is_cassette_available.call ? uuid.call(name: :member_id) : SecureRandom.uuid }
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order, index: 1) : SecureRandom.hex(27/2) }
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
      expect(response.card_no).to eq(card_no_n_mask) # [FIXME] expect(response.card_no).to eq(card_no_n_mask.sub(/(\*)+(\d)+/) { $1 * (16 - 4) + $2 * 4 })
      expect(response.forward).to eq(res2.forward)
    end
  end

  describe '#entry_tran_btc' do
    let(:call_method) { '#entry_tran_btc' }
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
        :timeout        => 60,
        :item_memo      => 'これはDevelopment環境のテスト用の商品です。',
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

  describe '#get_rate_btc' do
    let(:call_method) { '#get_rate_btc' }
    it 'return 1 item' do
      args = {}
      response = client.get_rate_btc(args)
      expect(response.medium).not_to be(nil)
    end
  end

  describe '#search_trade_btc' do
    let(:call_method) { '#search_trade_btc' }
    let(:order_id) { is_cassette_available.call ? uuid.call(name: :order_id) : SecureRandom.hex(27/2) }
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
