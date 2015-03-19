# coding: utf-8

module GmoPayment
  class Client
    class Options
      # @param [Hash] opts
      # @option opts [String]  :api_endpoint
      # @option opts [String]  :proxy
      # @option opts [Integer] :verify_mode
      def initialize(opts = {})
        [:api_endpoint, :proxy, :verify_mode].each do |item|
          instance_variable_set(:"@#{item}", opts[item] || GmoPayment::Configure.__send__(item))
        end
      end

      # GMO API endpoint
      #
      # @return [String]
      def api_endpoint
        @api_endpoint ||= ENV['GMO_API_ENDPOINT']
      end

      # Proxy URI
      #
      # @return [URI::Generic, URI::HTTP]
      def proxy
        ::URI.parse(@proxy.to_s)
      end

      # SSL/TLS verify mode (VERIFY_PEER or VERIFY_NONE).
      # Defaults to: 1 (VERIFY_PEER).
      #
      # @return [Integer]
      def verify_mode
        @verify_mode ||= ::OpenSSL::SSL::VERIFY_PEER
      end
    end
  end
end
