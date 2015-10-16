# GmoPayment

Ruby client for the protocol type API provided by GMO Payment Gateway.

This library includes:

- Credit-Card protocol API - Version: 2014/03/18 1.13
- Multi-Payment protocol API (Bitcoin) - Version: 2015/04/01 1.32
- ErrorCode - Version: 2015/02/26 1.43

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gmo_payment'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gmo_payment

## Basic usage

```ruby
require 'gmo_payment'

client = GmoPayment::Client.new(api_endpoint: 'example.com')
response = client.entry_tran(
  :shop_id   => 'SHOP_ID',
  :shop_pass => 'SHOP_PASS',
  :order_id  => 'xxxxx',
  :job_cd    => 'CHECK'
)
```

### Setup in advance

```ruby
require 'gmo_payment'

GmoPayment.setup do |c|
  c.api_endpoint = 'example.com'
  c.proxy        = 'https://user:password@proxy.com:443/'
  c.verify_mode  = ::OpenSSL::SSL::VERIFY_PEER
  c.error_list   = 'path/to/file.yml'
  c.site_id      = 'GMO_SITE_ID'
  c.site_pass    = 'GMO_SITE_PASS'
  c.shop_id      = 'GMO_SHOP_ID'
  c.shop_pass    = 'GMO_SHOP_PASS'
end

client = GmoPayment::Client.new
response = client.entry_tran(
  :order_id => 'xxxxx',
  :job_cd   => 'CHECK'
)
```

## Generator

You can use generator in Ruby on Rails:

    $ bin/rails g gmo_payment:install

## Test

If you want to test in your environment, you have to define:

- GMO_TEST_API_ENDPOINT
- GMO_TEST_SITE_ID
- GMO_TEST_SITE_PASS
- GMO_TEST_SHOP_ID
- GMO_TEST_SHOP_PASS
- GMO_TEST_CARD_EXPIRE
- GMO_TEST_CARD_NO_N
  => _Non-ACS test card number_
- GMO_TEST_CARD_NO_N_MASK
- GMO_TEST_CARD_NO_Y
  => _ACS test card number_
- GMO_TEST_CARD_NO_Y_MASK
- GMO_TEST_ACS_URL
- GMO_TEST_BTC_URL

## Contributing

1. Fork it (https://github.com/kouhe-fuji/gmo_payment/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This library is under the [MIT License](https://opensource.org/licenses/MIT).
