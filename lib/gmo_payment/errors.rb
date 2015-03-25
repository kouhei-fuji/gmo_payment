# coding: utf-8

module GmoPayment
  # Basic error of GmoPayment
  class Errors < StandardError
    # Network Error
    #
    # @see GmoPayment::Client::NETWORK_ERRORS
    class NetworkError < self
      # @!attribute [rw] called_method
      # @!attribute [rw] request
      attr_accessor :called_method, :request

      # @param [Symbol]  called_method
      # @param [String]  message
      # @param [Request] request
      def initialize(called_method = nil, request = nil, message = nil)
        self.called_method = called_method
        self.request = request
        super(message)
      end
    end

    # Error of request body has missing items.
    class RequestMissingItemError < self
      # @!attribute [rw] called_method
      # @!attribute [rw] items
      attr_accessor :called_method, :items

      # @param [Symbol] called_method
      # @param [Array]  items
      def initialize(called_method = nil, items = [])
        self.called_method = called_method
        self.items = items
        super(items.join(', '))
      end
    end

    # Error of request body has invalid items.
    class RequestInvalidItemError < self
      # @!attribute [rw] called_method
      # @!attribute [rw] items
      attr_accessor :called_method, :items

      # @param [Symbol] called_method
      # @param [Hash]   items
      def initialize(called_method = nil, items = {})
        self.called_method = called_method
        self.items = items
        super(items.map { |k, v| ":#{k} (#{v})" }.join(', '))
      end
    end

    # Error of response HTTP is not 2xx.
    class ResponseHTTPError < self
      # @!attribute [rw] called_method
      # @!attribute [rw] request
      attr_accessor :called_method, :request

      # @param [Symbol]  called_method
      # @param [Request] request
      def initialize(called_method = nil, request = nil)
        self.called_method = called_method
        self.request = request
        super("HTTP response called from `#{called_method}' is not 2xx")
      end
    end

    # Error of response body has "ErrCode".
    class ResponseHasErrCodeError < self
      # @!attribute [rw] called_method
      # @!attribute [rw] response
      attr_accessor :called_method, :response

      # @param [Symbol]   called_method
      # @param [Response] response
      def initialize(called_method = nil, response = nil)
        self.called_method = called_method
        self.response = response
        super("HTTP response called from `#{called_method}' has ErrCode")
      end

      # @param [String] file
      # @return [Hash]
      def error_messages(file = nil)
        require 'yaml'
        error_list = YAML.load_file(file || GmoPayment::Configure.error_list)
        self.response.err_info.each_with_object({}) do |error, hash|
          hash[error] = error_list[error]
        end
      end
    end

  end
end
