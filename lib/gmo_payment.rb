# coding: utf-8
require 'gmo_payment/version'
require 'gmo_payment/glossary'
require 'gmo_payment/configure'
require 'gmo_payment/errors'
require 'gmo_payment/client'

module GmoPayment
  class << self
    # Setup {GmoPayment::Configure} variables.
    # @example
    #   GmoPayment.setup do |c|
    #     c.api_endpoint  = 'example.com'
    #     c.proxy         = 'https://user:password@proxy.com:443/'
    #     c.verify_mode   = ::OpenSSL::SSL::VERIFY_PEER
    #     c.error_message = 'path/to/file.yml'
    #     c.site_id       = 'GMO_SITE_ID'
    #     c.site_pass     = 'GMO_SITE_PASS'
    #     c.shop_id       = 'GMO_SHOP_ID'
    #     c.shop_pass     = 'GMO_SHOP_PASS'
    #   end
    def setup(&block)
      GmoPayment::Configure.setup(&block)
    end

    # Reset {GmoPayment::Configure} variables.
    def reset!
       GmoPayment::Configure.reset!
    end
  end
end
