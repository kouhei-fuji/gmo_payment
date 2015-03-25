# coding: utf-8
require 'rails/generators/base'

module GmoPayment
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      desc 'Copy GmoPayment error message locale file to your application.'

      def copy_locales
        copy_file 'ja.yml', 'app/config/locales/gmo_payment.ja.yml'
      end
    end
  end
end
