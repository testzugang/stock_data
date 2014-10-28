require 'rubygems'
require 'rest-client'
require 'json'
require 'date'
include StockQuote::Utility

module StockQuote

  # Abstract class for Yahoo Finance queries.
  class YahooFinanceQuery

    attr_accessor :response_code, :no_data_message

    def initialize(data)
      if data['ErrorIndicationreturnedforsymbolchangedinvalid']
        @no_data_message = data['ErrorIndicationreturnedforsymbolchangedinvalid']
        @response_code = 404
      elsif data['diagnostics'] && data['diagnostics']['warning']
        @no_data_message = data['diagnostics']['warning']
        @response_code = 404
      elsif data['count'] && data['count'] == 0
        @no_data_message = 'Query returns no valid data'
        @response_code = 404
      else
        @response_code = 200
        data.map do |k, v|
          instance_variable_set("@#{to_underscore(k)}", (v.nil? ? nil : to_format(v)))
        end
      end
    end

    def self.parse(json, symbol, format='instance')
      raise Exception
    end

    def self.request_query(format, symbol, url)
      RestClient.get(url) do |response|
        if response.code == 200
          parse(response, symbol, format)
        else
          warn "[BAD REQUEST] #{ url }"
          NoDataForStockError.new
        end
      end
    end

    def self.format_select(select, fields = [])
      return select if select.is_a?(String) && !!('*'.match(/\*/))
      select = select.split(',') if select.is_a?(String)
      select = select.reject { |e| !(fields.include? e) }
      select.length > 0 ? select.join(',') : '*'
    end

  end

end
