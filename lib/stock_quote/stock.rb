require 'rubygems'
require 'rest-client'
require 'json'
require 'date'
require 'stock_quote/yahoo_finance_query'
include StockQuote::Utility

module StockQuote

  # Queries Yahoo for stock information.
  class Stock < YahooFinanceQuery
    FIELDS = %w(symbol CompanyName Sector Industry start end FullTimeEmployees)

    FIELDS.each do |field|
      __send__(:attr_accessor, to_underscore(field).to_sym)
    end

    def self.fields
      FIELDS
    end

    def self.stock(symbol, select = '*', format = 'instance')
      select = format_select(select, FIELDS)
      url = URI.encode("SELECT #{ select } FROM yahoo.finance.stocks WHERE symbol='#{symbol}'")
      request_query(format, symbol, url)
    end

    def self.parse(json, symbol, format='instance')
      json = JSON.parse(json).fetch('query')
      count = json['count']
      raise NoDataForStockError.new(json) if count == 0
      return json['results'] if !!(format=='json')

      data = json['results']['stock']
      data['symbol'] = to_p(symbol) unless data['symbol']
      Stock.new(data)
    end

  end

end
