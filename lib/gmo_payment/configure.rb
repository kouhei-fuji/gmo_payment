# coding: utf-8

module GmoPayment
  module Configure
    class << self
      # @!attribute [rw] api_endpoint
      # @!attribute [rw] proxy
      # @!attribute [rw] verify_mode
      # @!attribute [rw] error_message
      # @!attribute [rw] site_id
      # @!attribute [rw] site_pass
      # @!attribute [rw] shop_id
      # @!attribute [rw] shop_pass
      attr_accessor :api_endpoint, :proxy, :verify_mode, :error_message, :site_id, :site_pass, :shop_id, :shop_pass

      # See {GmoPayment.setup}
      def setup
        yield(self)
      end

      # See {GmoPayment.reset!}
      def reset!
        instance_variables.each do |variable|
          remove_instance_variable(variable)
        end
      end
    end

  end
end
