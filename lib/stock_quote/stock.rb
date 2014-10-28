require 'rubygems'
require 'rest-client'
require 'json'
require 'date'
require 'stock_quote/yahoo_finance_query'
include StockQuote::Utility

module StockQuote

  # Queries Yahoo for stock information.
  class Quotes < YahooFinanceQuery
    FIELDS = %w(Symbol)

    FIELDS.each do |field|
      __send__(:attr_accessor, to_underscore(field).to_sym)
    end

    def self.fields
      FIELDS
    end

  end

end
