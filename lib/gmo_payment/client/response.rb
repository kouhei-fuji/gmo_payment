# coding: utf-8

module GmoPayment
  class Client
    class Response
      # @param [Symbol] called_method
      # @param [Net::HTTPResponse] response
      def initialize(called_method, response)
        @called_method = called_method
        @response = response
      end

      # Whether {#prebody} which of Hash values should return array or not.
      # If called {GmoPayment::Api#search_card}, it will return true.
      def called_return_array?
        @called_method == :search_card
      end

      # When generating {#prebody}, whether to use {#split_encoded_raw_body} or not.
      # If called {GmoPayment::Api#search_trade_btc}, it will return true.
      def called_split_normal?
        @called_method != :search_trade_btc
      end

      # HTTP response header.
      #
      # @return [Hash]
      def http_header
        hash = {}
        @response.each do |key, value|
          hash[key] = value
        end
        hash
      end

      # HTTP status code.
      #
      # @return [Integer]
      def http_code
        @response.code.to_i
      end

      # HTTP status message.
      #
      # @return [String]
      def http_message
        @response.message.to_s
      end

      # Reponse body as it is.
      #
      # @return [String]
      def raw_body
        @response.body.to_s
      end

      # Encode {#raw_body} Shift_JIS to UTF-8.
      #
      # @return [String]
      def encoded_raw_body
        self.raw_body.encode('UTF-8', 'Shift_JIS', :invalid => :replace, :undef => :replace)
      end

      # Split {#encoded_raw_body} by {GmoPayment::GLOSSARY} keys.
      # It works like URI.decode_www_form.
      #
      # @example
      #   "AccessID=xxx&AccessPass=zzz-1|zzz-2&PayTimes="
      #   # => [["AccessID", ["xxx"]], ["AccessPass", ["zzz-1", "zzz-2"]]] # PayTimes is unavailable.
      #
      # @return [Array]
      def split_encoded_raw_body
        return_array = []
        array = self.encoded_raw_body.split(/(&?#{GmoPayment::GLOSSARY.values.join('=)|(&?')}=)/).values_at(1..-1)
        array.each_slice(2) do |(key, value)|
          next if value.nil? || value.empty?
          return_array << [key.gsub(/[&=]/, ''), value.split('|')]
        end
        return_array
      end

      # Split {#encoded_raw_body} by "&" and "=".
      # It works like URI.decode_www_form.
      #
      # @example
      #   "A=a&B=&C=c-1|c-2"
      #   # => [["A", ["a"]], ["C", ["c-1", "c-2"]]] # B is unavailable.
      #
      # @return [Array]
      def split_encoded_raw_body!
        self.encoded_raw_body.split('&').map do |elem|
          key, value = elem.split('=', 2)
          [key, value.split('|')] unless value.nil? || value.empty?
        end.compact
      end

      # Convert response body to an easy-to-use format.
      #
      # @return [Hash]
      #   Hash<String, Array> if {#encoded_raw_body} has "ErrCode" or {#called_return_array?} is true.
      #   The other cases, it will return Hash<String, String>.
      def prebody
        array = called_split_normal? ? self.split_encoded_raw_body : self.split_encoded_raw_body!
        array.each_with_object({}) do |(key, value), hash|
          if called_return_array? || ['ErrCode', 'ErrInfo'].include?(key)
            hash[key] = value
          else
            hash[key] = value.join('|')
          end
        end
      end

      # Convert {#prebody} keys to Symbol that is {GmoPayment::GLOSSARY} key.
      #
      # @return [Hash]
      def body
        self.prebody.each_with_object({}) do |(key, value), hash|
          hash[GmoPayment::GLOSSARY.key(key) || key] = value
        end
      end

      # Whether HTTP response is not 2xx.
      def http_error?
        !(200..299).include?(http_code)
      end

      # Whether response body has "ErrCode" or not.
      def error?
        self.body.keys.include?(:err_code)
      end

      # Define {GmoPayment::GLOSSARY} keys' name to methods.
      #
      # @!method access_id
      # @!method access_pass
      # @!method acs
      # @!method acs_url
      # @!method amount
      # @!method approve
      # @!method card_name
      # @!method card_no
      # @!method card_pass
      # @!method card_seq
      # @!method check_string
      # @!method client_field_1
      # @!method client_field_2
      # @!method client_field_3
      # @!method client_field_flag
      # @!method currency
      # @!method default_flag
      # @!method delete_flag
      # @!method device_category
      # @!method err_code
      # @!method err_info
      # @!method expire
      # @!method forward
      # @!method holder_name
      # @!method http_accept
      # @!method http_user_agent
      # @!method item_code
      # @!method item_memo
      # @!method item_name
      # @!method job_cd
      # @!method md
      # @!method member_id
      # @!method member_name
      # @!method method
      # @!method order_id
      # @!method pa_req
      # @!method pa_res
      # @!method pay_times
      # @!method pay_type
      # @!method pin
      # @!method process_date
      # @!method recv_res
      # @!method ret_url
      # @!method security_code
      # @!method seq_mode
      # @!method shop_id
      # @!method shop_pass
      # @!method site_id
      # @!method site_pass
      # @!method start_url
      # @!method status
      # @!method tax
      # @!method td_flag
      # @!method td_tenant_name
      # @!method term_url
      # @!method token
      # @!method tran_id
      # @!method tran_date
      GmoPayment::GLOSSARY.each_key do |key|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{key}
            self.body[__method__]
          end
        RUBY
      end

    end
  end
end
