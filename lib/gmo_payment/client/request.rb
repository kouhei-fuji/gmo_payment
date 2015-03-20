# coding: utf-8
require 'base64'

module GmoPayment
  class Client
    class Request
      # @param [Symbol] called_method
      # @param [Hash]   args
      def initialize(called_method, args)
        @called_method = called_method
        input =
          args.each_with_object({}) do |(k, v), hash|
            key = k.to_s.downcase.to_sym
            value = case key
              when :job_cd
                v.to_s.upcase
              when :amount, :tax, :td_flag, :method, :pay_times, :seq_mode, :default_flag, :card_seq
                v.to_i.to_s
              else
                v.to_s
              end
            hash[key] = value
          end
        [:site_id, :site_pass, :shop_id, :shop_pass].each do |key|
          if all_items.include?(key)
            input[key] ||= GmoPayment::Configure.__send__(key) || ENV[GmoPayment::GLOSSARY[key]]
          end
        end
        @input = input.reject { |_, v| v.nil? }
        @missing_items = self.missing_items
        @invalid_items = self.invalid_items
      end

      # Check missing items.
      #
      # @return [Array]
      def missing_items
        return @missing_items if @missing_items

        array = case @called_method
          when :entry_tran
            if @input[:job_cd] && ['CAPTURE', 'AUTH', 'SAUTH'].include?(@input[:job_cd])
              required_items << :amount
            else
              required_items
            end
          when :exec_tran, :exec_tran_3d, :exec_tran_member, :exec_tran_member_3d, :re_exec_tran
            if @input[:method] && ['2', '4'].inlcude?(@input[:method])
              required_items << :pay_times
            else
              required_items
            end
          else
            required_items
          end
        @missing_items = array.select { |item| @input[item].nil? }
      end

      # Whether to have missing items or not.
      #
      # @return [Boolean]
      def missing?
        !missing_items.empty?
      end

      # Validate to have invalid items.
      #
      # @return [Hash]
      def invalid_items
        return @invalid_items if @invalid_items

        items = @input.select { |k, v| validate_invalid?(k, v) if all_items.include?(k) }
        case @called_method
        when :entry_tran, :re_exec_tran, :change_tran
          unless (1..9_999_999).include?(@input[:amount].to_i + @input[:tax].to_i)
            items[:amount] = @input[:amount] if @input[:amount]
            items[:tax]    = @input[:tax]    if @input[:tax]
          end
        when :entry_tran_btc
          unless (1..300_000).include?(@input[:amount].to_i + @input[:tax].to_i)
            items[:amount] = @input[:amount] if @input[:amount]
            items[:tax]    = @input[:tax]    if @input[:tax]
          end
        end
        @invalid_items = items
      end

      # Whether to have invalid items or not.
      #
      # @return [Bloolean]
      def invalid?
        !invalid_items.empty?
      end

      # Request body.
      #
      # @return [String, nil]
      def body
        body_hash =
          @input.each_with_object({}) do |(k, v), hash|
            next unless (key = GmoPayment::GLOSSARY[k]) && all_items.include?(k)
            hash[key] = k == :td_tenant_name ? encode_euc_base64(v) : encode_sjis(v)
          end
        body = ::URI.encode_www_form(body_hash)
        body.empty? ? nil : body
      end

      private

      # @param [String] str
      # @return [String] String of encoding to Base64 encoded in EUC-JP.
      def encode_euc_base64(str)
        ::Base64.strict_encode64(str.encode('EUC-JP', :invalid => :replace, :undef => :replace))
      end

      # @param [String] str
      # @return [String] String encoded in Shif_JIS.
      def encode_sjis(str)
        str.encode('Shift_JIS', :invalid => :replace, :undef => :replace)
      end

      # @return [Array]
      def all_items
        required_items + optional_items
      end

      # @return [Array]
      def required_items
        case @called_method
        when :entry_tran
          [:shop_id, :shop_pass, :order_id, :job_cd]
        when :exec_tran
          [:access_id, :access_pass, :order_id, :card_no, :expire]
        when :exec_tran_3d
          [:access_id, :access_pass, :order_id, :card_no, :expire, :http_accept, :http_user_agent, :device_category]
        when :secure_tran
          [:pa_res, :md]
        when :save_member, :update_member, :delete_member, :search_member
          [:site_id, :site_pass, :member_id]
        when :save_card
          [:site_id, :site_pass, :member_id, :card_no, :expire]
        when :update_card
          [:site_id, :site_pass, :member_id, :card_seq, :card_no, :expire]
        when :delete_card
          [:site_id, :site_pass, :member_id, :card_seq]
        when :search_card
          [:site_id, :site_pass, :member_id, :seq_mode]
        when :exec_tran_member
          [:access_id, :access_pass, :order_id, :site_id, :site_pass, :member_id, :card_seq]
        when :exec_tran_member_3d
          [:access_id, :access_pass, :order_id, :site_id, :site_pass, :member_id, :card_seq, :http_accept, :http_user_agent, :device_category]
        when :delete_tran
          [:shop_id, :shop_pass, :access_id, :access_pass, :job_cd]
        when :re_exec_tran
          [:shop_id, :shop_pass, :access_id, :access_pass, :job_cd, :amount, :method]
        when :auth_to_sales, :change_tran
          [:shop_id, :shop_pass, :access_id, :access_pass, :job_cd, :amount]
        when :search_trade
          [:shop_id, :shop_pass, :order_id]
        when :save_traded_card
          [:shop_id, :shop_pass, :order_id, :site_id, :site_pass, :member_id]
        when :entry_tran_btc
          [:shop_id, :shop_pass, :order_id, :amount]
        when :exec_tran_btc
          [:shop_id, :access_id, :access_pass, :order_id, :ret_url, :item_name, :item_memo]
        when :search_trade_btc
          [:shop_id, :shop_pass, :order_id, :pay_type]
        else
          []
        end
      end

      # @return [Array]
      def optional_items
        case @called_method
        when :entry_tran
          [:item_code, :amount, :tax, :td_flag, :td_tenant_name]
        when :exec_tran
          [:method, :pay_times, :security_code, :pin, :client_field_1, :client_field_2, :client_field_3, :client_field_flag]
        when :exec_tran_3d
          [:method, :pay_times, :security_code, :client_field_1, :client_field_2, :client_field_3, :client_field_flag]
        when :save_member, :update_member
          [:member_name]
        when :save_card, :update_card
          [:seq_mode, :default_flag, :card_name, :card_pass, :holder_name]
        when :delete_card
          [:seq_mode]
        when :search_card
          [:card_seq]
        when :exec_tran_member, :exec_tran_member_3d
          [:method, :pay_times, :seq_mode, :card_pass, :security_code, :client_field_1, :client_field_2, :client_field_3, :client_field_flag]
        when :re_exec_tran
          [:tax, :pay_times]
        when :change_tran, :entry_tran_btc
          [:tax]
        when :save_traded_card
          [:seq_mode, :default_flag, :holder_name]
        when :exec_tran_btc
          [:client_field_1, :client_field_2, :client_field_3]
        else
          []
        end
      end

      # @param [Symbol] key
      # @param [String] value
      # @return [Boolean]
      def validate_invalid?(key, value)
        !validate_valid?(key, value)
      end

      # @param [Symbol] key
      # @param [String] value
      # @return [Boolean]
      def validate_valid?(key, value)
        case key
        when :access_id, :access_pass
          value.length <= 32
        when :amount, :tax
          (value =~ /\D/).nil? && value.length <= 7
        when :card_name
          value.length <= 10
        when :card_no
          (value =~ /\D/).nil? && (10..16).include?(value.length)
        when :card_pass
          (value =~ /[^a-zA-Z0-9]/).nil? && value.length <= 20
        when :card_seq
          (value =~ /\D/).nil? && value.length <= 4
        when :client_field_1, :client_field_2, :client_field_3
          (value =~ /[\{\}\|^`~&<>"']/).nil? && value.length <= 100
        when :client_field_flag, :default_flag, :device_category, :seq_mode, :td_flag
          ['0', '1'].include?(value)
        when :expire
          (value =~ /\D/).nil? && value.length == 4
        when :holder_name
          (value =~ /[^a-zA-Z0-9\s]/).nil? && value.length <= 50
        when :item_code
          (value =~ /\D/).nil? && value.length == 7
        when :item_memo
          value.length <= 128
        when :item_name
          value.length <= 64
        when :job_cd
          case @called_method
          when :entry_tran
            ['CHECK', 'CAPTURE', 'AUTH', 'SAUTH'].include?(value)
          when :delete_tran
            ['VOID', 'RETURN', 'RETURNX'].include?(value)
          when :re_exec_tran
            ['CAPTURE', 'AUTH'].include?(value)
          when :change_tran
            ['CAPTURE', 'AUTH', 'SAUTH'].include?(value)
          end
        when :member_id
          (value =~ /[^\w\-\.@]/).nil? && value.length <= 60
        when :member_name
          (value =~ /[\{\}\|^`~&<>"']/).nil? && value.length <= 255
        when :method
          ['1', '2', '3', '4', '5'].include?(value)
        when :order_id
          (value =~ /[^a-zA-Z0-9\-]/).nil? && value.length <= 27
        when :pay_times
          (value =~ /\D/).nil? && value.length <= 2
        when :pin
          value.length <= 4
        when :ret_url
          value.length <= 256
        when :security_code
          (value =~ /\D/).nil? && (3..4).include?(value.length)
        when :shop_id, :site_id
          value.length <= 13
        when :shop_pass
          value.length <= 10
        when :site_pass
          value.length <= 20
        when :td_tenant_name
          encode_euc_base64(value).bytesize <= 25
        else
          true
        end
      end

    end
  end
end
