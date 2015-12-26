# coding: utf-8
require 'net/https'
require 'gmo_payment/client/options'
require 'gmo_payment/client/request'
require 'gmo_payment/client/response'

module GmoPayment
  class Client
    # Network errors that may occur when sending a request.
    #
    # @see https://github.com/aws/aws-sdk-ruby/blob/master/aws-sdk-core/lib/seahorse/client/net_http/handler.rb#L9-L13 aws/aws-sdk-ruby
    # @see https://github.com/edward/net_http_exception_fix/blob/master/lib/net_http_exception_fix.rb edward/net_http_exception_fix
    #
    # @return [Array]
    NETWORK_ERRORS = [
      ::SocketError, ::EOFError, ::Timeout::Error, ::OpenSSL::SSL::SSLError,
      ::Errno::ECONNABORTED, ::Errno::ECONNRESET, ::Errno::ECONNREFUSED,
      ::Errno::EINVAL, ::Errno::EPIPE, ::Errno::ETIMEDOUT,
      ::Net::ProtocolError, ::Net::HTTPHeaderSyntaxError, ::Net::HTTPBadResponse,
    ]

    # @param [Hash] opts
    # @see {Options#initialize}
    def initialize(opts = {})
      @options = Options.new(opts)
    end

    # Call the GMO-PG API.
    #
    # @param [Hash] args
    # @param [Symbol] method
    # @return [Response]
    # @raise [NetworkError]
    # @raise [RequestMissingItemError]
    # @raise [RequestInvalidItemError]
    # @raise [ResponseHTTPError]
    # @raise [ResponseHasErrCodeError]
    def call(method, args)
      request = Request.new(method, args)
      raise GmoPayment::Errors::RequestMissingItemError.new(method, request.missing_items) if request.missing?
      raise GmoPayment::Errors::RequestInvalidItemError.new(method, request.invalid_items) if request.invalid?

      http_request = ::Net::HTTP::Post.new(post_path(method), header)
      if request_body = request.body
        http_request.body           = request_body
        http_request.content_length = request_body.bytesize
        http_request.content_type   = 'application/x-www-form-urlencoded'
      end

      proxy = @options.proxy
      http = ::Net::HTTP.new(@options.api_endpoint, 443,
        proxy.host, proxy.port, proxy.user, proxy.password)
      http.use_ssl      = true
      http.ssl_version  = :TLSv1_2
      http.verify_mode  = @options.verify_mode
      http.ssl_timeout  = 120
      http.open_timeout = 15
      http.read_timeout = 90

      res = http.request(http_request)
    rescue *NETWORK_ERRORS => error
      raise GmoPayment::Errors::NetworkError.new(method, request, error.message)
    else
      response = Response.new(method, res)
      raise GmoPayment::Errors::ResponseHTTPError.new(method, request)        if response.http_error?
      raise GmoPayment::Errors::ResponseHasErrCodeError.new(method, response) if response.error?

      response
    end

    # [2.1.2.1 取引登録]
    # これ以降の決済取引で必要となる取引IDと取引パスワードの発行を行い、取引を開始します。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id   required
    # @option args [String]  :shop_pass required
    # @option args [String]  :order_id  required
    # @option args [String]  :job_cd    required
    # @option args [Integer] :amount    required if :job_cd is not CHECK
    # @option args [String]  :item_code
    # @option args [Integer] :tax
    # @option args [Integer] :td_flag (0)
    # @option args [String]  :td_tenant_name
    # @return [Response]
    def entry_tran(args = {})
      if args[:job_cd] == 'CHECK'
        args.delete(:amount)
        args.delete(:tax)
      end
      call(__method__, args)
    end

    # [2.1.2.2 決済実行]
    # お客様が入力したカード番号と有効期限の情報でカード会社と通信を行い決済を実施し、結果を返します。
    #
    # @param [Hash] args
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [String]  :order_id    required
    # @option args [String]  :card_no     required
    # @option args [String]  :expire      required
    # @option args [Integer] :method      required if :job_cd is not CHECK
    # @option args [Integer] :pay_times   required if :method is 2 or 4
    # @option args [String]  :pin         required if you contracted to use this
    # @option args [String]  :security_code
    # @option args [String]  :client_field_1
    # @option args [String]  :client_field_2
    # @option args [String]  :client_field_3
    # @return [Response]
    def exec_tran(args = {})
      args[:client_field_flag] = 1
      call(__method__, args)
    end

    # [2.2.2.2 決済実行（本人認証サービス有）]
    # お客様が入力したカード番号と有効期限の情報でカード会社と通信を行い決済を実施し、結果を返します。
    #   カード情報が本人認証サービスに対応していない場合は、カード会社との通信を行い決済を実行します。
    #   その際の出力パラメータは「2.1.2.2 決済実行」の出力パラメータと同じになります。
    #
    # @param [Hash] args
    # @option args [String]  :access_id       required
    # @option args [String]  :access_pass     required
    # @option args [String]  :order_id        required
    # @option args [String]  :card_no         required
    # @option args [String]  :expire          required
    # @option args [String]  :http_accept     required
    # @option args [String]  :http_user_agent required
    # @option args [Integer] :method          required if :job_cd is not CHECK
    # @option args [Integer] :pay_times       required if :method is 2 or 4
    # @option args [String]  :security_code
    # @option args [String]  :client_field_1
    # @option args [String]  :client_field_2
    # @option args [String]  :client_field_3
    # @return [Response]
    def exec_tran_3d(args = {})
      args[:client_field_flag] = 1
      args[:device_category] = 0
      call(__method__, args)
    end

    # [2.2.2.4 認証後決済実行（本人認証サービス有）]
    # 本人認証サービスの結果を解析し、その情報を使用してカード会社と通信を行い決済を実施して結果を返します。
    #
    # @param [Hash] args
    # @option args [String] :pa_res required
    # @option args [String] :md     required
    # @return [Response]
    def secure_tran(args = {})
      call(__method__, args)
    end

    # [2.3.2.1 会員登録]
    # 指定されたサイトに会員を登録します。
    #
    # @param [Hash] args
    # @option args [String] :site_id   required
    # @option args [String] :site_pass required
    # @option args [String] :member_id required
    # @option args [String] :member_name
    # @return [Response]
    def save_member(args = {})
      call(__method__, args)
    end

    # [2.4.2.1 会員更新]
    # 指定されたサイトに会員情報を更新します。
    #
    # @param [Hash] args
    # @option args [String] :site_id   required
    # @option args [String] :site_pass required
    # @option args [String] :member_id required
    # @option args [String] :member_name
    # @return [Response]
    def update_member(args = {})
      call(__method__, args)
    end

    # [2.5.2.1 会員削除]
    # 指定したサイトから会員情報を削除します。
    #
    # @param [Hash] args
    # @option args [String] :site_id   required
    # @option args [String] :site_pass required
    # @option args [String] :member_id required
    # @return [Response]
    def delete_member(args = {})
      call(__method__, args)
    end

    # [2.6.2.1 会員参照]
    # 指定したサイトの会員情報を参照します。
    #
    # @param [Hash] args
    # @option args [String] :site_id   required
    # @option args [String] :site_pass required
    # @option args [String] :member_id required
    # @return [Response]
    def search_member(args = {})
      call(__method__, args)
    end

    # [2.7.2.1 カード登録]
    # 指定した会員にカード情報を登録します。
    # 尚、サイトに設定されたショップIDを使用してカード会社と通信を行い、有効性の確認を行います。
    #
    # @param [Hash] args
    # @option args [String]  :site_id   required
    # @option args [String]  :site_pass required
    # @option args [String]  :member_id required
    # @option args [String]  :card_no   required
    # @option args [String]  :expire    required
    # @option args [Integer] :seq_mode (0)
    # @option args [Integer] :default_flag (0)
    # @option args [String]  :card_name
    # @option args [String]  :card_pass
    # @option args [String]  :holder_name
    # @return [Response]
    def save_card(args = {})
      call(__method__, args)
    end

    # [2.7.2.1 カード更新]
    # 指定した会員のカード情報を更新します。
    # 尚、サイトに設定されたショップIDを使用してカード会社と通信を行い、有効性の確認を行います。
    #
    # @param [Hash] args
    # @option args [String]  :site_id   required
    # @option args [String]  :site_pass required
    # @option args [String]  :member_id required
    # @option args [Integer] :card_seq  required
    # @option args [String]  :card_no   required
    # @option args [String]  :expire    required
    # @option args [Integer] :seq_mode (0)
    # @option args [Integer] :default_flag (0)
    # @option args [String]  :card_name
    # @option args [String]  :card_pass
    # @option args [String]  :holder_name
    # @return [Response]
    def update_card(args = {})
      call(__method__, args)
    end

    # [2.8.2.1 カード削除]
    # 指定した会員のカード情報を削除します。
    #
    # @param [Hash] args
    # @option args [String]  :site_id   required
    # @option args [String]  :site_pass required
    # @option args [String]  :member_id required
    # @option args [Integer] :card_seq  required
    # @option args [Integer] :seq_mode (0)
    # @return [Response]
    def delete_card(args = {})
      call(__method__, args)
    end

    # [2.9.2.1 カード参照]
    # 指定した会員のカード情報を参照します。
    #
    # @param [Hash] args
    # @option args [String]  :site_id   required
    # @option args [String]  :site_pass required
    # @option args [String]  :member_id required
    # @option args [Integer] :seq_mode  required
    # @option args [Integer] :card_seq
    # @return [Response]
    def search_card(args = {})
      call(__method__, args)
    end

    # [2.10.2.3 決済実行]
    # お客様が選択したカード登録連番のカード情報を取得します。
    # 取得したカード情報でカード会社と通信を行い決済を実施し、結果を返します。
    #
    # @param [Hash] args
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [String]  :order_id    required
    # @option args [String]  :site_id     required
    # @option args [String]  :site_pass   required
    # @option args [String]  :member_id   required
    # @option args [Integer] :card_seq    required
    # @option args [Integer] :method      required if :job_cd is not CHECK
    # @option args [Integer] :pay_times   required if :method is 2 or 4
    # @option args [String]  :card_pass   required if :card_pass is set
    # @option args [Integer] :seq_mode (0)
    # @option args [String]  :security_code
    # @option args [String]  :client_field_1
    # @option args [String]  :client_field_2
    # @option args [String]  :client_field_3
    # @return [Response]
    def exec_tran_member(args = {})
      args[:client_field_flag] = 1
      call(__method__, args)
    end

    # [2.11.2.3 決済実行]
    # お客様が選択したカード登録連番のカード情報を取得します。
    #   カード情報が本人認証サービスに対応していない場合は、カード会社との通信を行い決済を実行します。
    #   その際の出力パラメータは「2.10.2.3 決済実行」の出力パラメータと同じになります。
    #
    # @param [Hash] args
    # @option args [String]  :access_id       required
    # @option args [String]  :access_pass     required
    # @option args [String]  :order_id        required
    # @option args [String]  :site_id         required
    # @option args [String]  :site_pass       required
    # @option args [String]  :member_id       required
    # @option args [Integer] :card_seq        required
    # @option args [String]  :http_accept     required
    # @option args [String]  :http_user_agent required
    # @option args [Integer] :method          required if :job_cd is not CHECK
    # @option args [Integer] :pay_times       required if :method is 2 or 4
    # @option args [Integer] :seq_mode (0)
    # @option args [String]  :card_pass
    # @option args [String]  :security_code
    # @option args [String]  :client_field_1
    # @option args [String]  :client_field_2
    # @option args [String]  :client_field_3
    # @return [Response]
    def exec_tran_member_3d(args = {})
      args[:client_field_flag] = 1
      args[:device_category] = 0
      call(__method__, args)
    end

    # [2.12.2.1 決済変更（取消）]
    # 決済が完了した取引に対して決済内容の取り消しを行います。
    # 指定された取引情報を使用してカード会社と通信を行い取り消しを実施します。
    #
    # @param [Hash] args
    # @option args [String] :shop_id     required
    # @option args [String] :shop_pass   required
    # @option args [String] :access_id   required
    # @option args [String] :access_pass required
    # @option args [String] :job_cd      required
    # @return [Response]
    def delete_tran(args = {})
      call(__method__, args)
    end

    # [2.13.2.1 決済変更（再オーソリ）]
    # 取り消されている決済に対して再オーソリを行います。指定された決済情報を使用してカード会社と通信を行い実施します。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id     required
    # @option args [String]  :shop_pass   required
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [String]  :job_cd      required
    # @option args [Integer] :amount      required
    # @option args [Integer] :method      required
    # @option args [Integer] :pay_times   required if :method is 2 or 4
    # @option args [Integer] :tax
    # @return [Response]
    def re_exec_tran(args = {})
      call(__method__, args)
    end

    # [2.14.2.1 決済変更（実売上）]
    # 仮売上の決済に対して実売上を行います。尚、実行時に仮売上時との金額チェックを行います。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id     required
    # @option args [String]  :shop_pass   required
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [Integer] :amount      required
    # @return [Response]
    def auth_to_sales(args = {})
      args[:job_cd] = 'SALES'
      call(__method__, args)
    end

    # [2.15.2.1 金額変更]
    # 決済が完了した取引に対して金額の変更を行います。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id     required
    # @option args [String]  :shop_pass   required
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [String]  :job_cd      required
    # @option args [Integer] :amount      required
    # @option args [Integer] :tax
    # @return [Response]
    def change_tran(args = {})
      call(__method__, args)
    end

    # [2.16.2.1 取引状態参照]
    # 指定したオーダーIDの取引情報を取得します。
    #
    # @param [Hash] args
    # @option args [String] :shop_id   required
    # @option args [String] :shop_pass required
    # @option args [String] :order_id  required
    # @return [Response]
    def search_trade(args = {})
      call(__method__, args)
    end

    # [2.17.2.1 決済後カード登録]
    # 指定されたオーダーIDの取引に使用したカードを登録します。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id   required
    # @option args [String]  :shop_pass required
    # @option args [String]  :order_id  required
    # @option args [String]  :site_id   required
    # @option args [String]  :site_pass required
    # @option args [String]  :member_id required
    # @option args [Integer] :seq_mode (0)
    # @option args [Integer] :default_flag (0)
    # @option args [String]  :holder_name
    # @return [Response]
    def save_traded_card(args = {})
      call(__method__, args)
    end

    # [18.1.2.1 取引登録 (BTC)]
    # これ以降の決済取引で必要となる取引IDと取引パスワードの発行を行い、取引を開始します。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id   required
    # @option args [String]  :shop_pass required
    # @option args [String]  :order_id  required
    # @option args [Integer] :amount    required
    # @option args [Integer] :tax
    # @return [Response]
    def entry_tran_btc(args = {})
      call(__method__, args)
    end

    # [18.1.2.2 決済実行 (BTC)]
    # 契約情報を確認し、これ以降の処理に必要なトークンを返却します。
    #
    # @param [Hash] args
    # @option args [String]  :shop_id     required
    # @option args [String]  :access_id   required
    # @option args [String]  :access_pass required
    # @option args [String]  :order_id    required
    # @option args [String]  :ret_url     required
    # @option args [String]  :item_name   required
    # @option args [Integer] :timeout     required
    # @option args [String]  :item_memo   required
    # @option args [String]  :client_field_1
    # @option args [String]  :client_field_2
    # @option args [String]  :client_field_3
    # @return [Response]
    def exec_tran_btc(args = {})
      call(__method__, args)
    end

    # [18.1.2.5 決済実行 (BTC)]
    # ビットコインのレート(参考値)を返却します。
    #
    # @note
    #   注意: このレートは、決済後の円換算レートを保証するものではございません。
    #   エンドユーザーに表示する場合等、参考値としてご利用下さい。
    #   また、レートはリクエストビットコインウォレット事業者から取得した値を返却しております。
    #   レートの更新頻度は、ウォレット事業者に依存いたします。
    #
    # @param [Hash] args
    # @option args [String] :shop_id   required
    # @option args [String] :shop_pass required
    def get_rate_btc(args = {})
      call(__method__, args)
    end

    # [21.1.2.1 取引状態参照 (BTC)]
    # 指定したオーダーIDの取引情報を取得します。
    #
    # @param [Hash] args
    # @option args [String] :shop_id   required
    # @option args [String] :shop_pass required
    # @option args [String] :order_id  required
    # @return [Response]
    def search_trade_btc(args = {})
      args[:pay_type] = 17
      call(__method__, args)
    end

    private

    # @param [Symbol] method
    # @return [String]
    def post_path(method)
      case method
      when :entry_tran
        '/payment/EntryTran.idPass'
      when :exec_tran, :exec_tran_3d, :exec_tran_member, :exec_tran_member_3d
        '/payment/ExecTran.idPass'
      when :secure_tran
        '/payment/SecureTran.idPass'
      when :save_member
        '/payment/SaveMember.idPass'
      when :update_member
        '/payment/UpdateMember.idPass'
      when :delete_member
        '/payment/DeleteMember.idPass'
      when :search_member
        '/payment/SearchMember.idPass'
      when :save_card, :update_card
        '/payment/SaveCard.idPass'
      when :delete_card
        '/payment/DeleteCard.idPass'
      when :search_card
        '/payment/SearchCard.idPass'
      when :delete_tran, :re_exec_tran, :auth_to_sales
        '/payment/AlterTran.idPass'
      when :change_tran
        '/payment/ChangeTran.idPass'
      when :search_trade
        '/payment/SearchTrade.idPass'
      when :save_traded_card
        '/payment/TradedCard.idPass'
      when :entry_tran_btc
        '/payment/EntryTranBTC.idPass'
      when :exec_tran_btc
        '/payment/ExecTranBTC.idPass'
      when :get_rate_btc
        '/payment/GetBTCRate.idPass'
      when :search_trade_btc
        '/payment/SearchTradeMulti.idPass'
      end
    end

    # @return [Hash]
    def header
      {
        'Accept'     => 'application/x-www-form-urlencoded;q=1.0,*/*;q=0.5',
        'User-Agent' => "RubyGem/GmoPayment/#{GmoPayment::VERSION}",
      }
    end

  end
end
