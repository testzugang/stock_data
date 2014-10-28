require 'rubygems'
require 'stock_quote/utility'
require 'stock_quote/version'
require 'stock_quote/quotes'

module StockQuote
# => SecQuote::NoDataForStockError
# Is returned for 404s and ErrorIndicationreturnedforsymbolchangedinvalid
  class NoDataForStockError < StandardError
    attr_reader :no_data_message

    def initialize(data = {}, *)
      if data['ErrorIndicationreturnedforsymbolchangedinvalid']
        @no_data_message = data['ErrorIndicationreturnedforsymbolchangedinvalid']
      elsif data['diagnostics'] && data['diagnostics']['warning']
        @no_data_message = data['diagnostics']['warning']
      elsif data['count'] && data['count'] == 0
        @no_data_message = 'Query returns no valid data'
      end
    end

    def failure?;
      true
    end

    def success?;
      false
    end

    def response_code;
      404
    end
  end

  def self.format_select(select, fields = [])
    return select if select.is_a?(String) && !!('*'.match(/\*/))
    select = select.split(',') if select.is_a?(String)
    select = select.reject { |e| !(fields.include? e) }
    select.length > 0 ? select.join(',') : '*'
  end

end