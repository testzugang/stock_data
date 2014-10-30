require 'rubygems'
require 'rest-client'
require 'json'
require 'date'
require 'stock_quote/yahoo_finance_query'
include StockQuote::Utility

module StockQuote

  # => SecQuote::Stock
  # Queries Yahoo for current and historical pricing.
  class Quotes < YahooFinanceQuery
    FIELDS = %w(Symbol Ask AverageDailyVolume Bid AskRealtime BidRealtime BookValue Change_PercentChange Change Commission ChangeRealtime AfterHoursChangeRealtime DividendShare LastTradeDate TradeDate EarningsShare ErrorIndicationreturnedforsymbolchangedinvalid EPSEstimateCurrentYear EPSEstimateNextYear EPSEstimateNextQuarter DaysLow DaysHigh YearLow YearHigh HoldingsGainPercent AnnualizedGain HoldingsGain HoldingsGainPercentRealtime HoldingsGainRealtime MoreInfo OrderBookRealtime MarketCapitalization MarketCapRealtime EBITDA ChangeFromYearLow PercentChangeFromYearLow LastTradeRealtimeWithTime ChangePercentRealtime ChangeFromYearHigh PercebtChangeFromYearHigh LastTradeWithTime LastTradePriceOnly HighLimit LowLimit DaysRange DaysRangeRealtime FiftydayMovingAverage TwoHundreddayMovingAverage ChangeFromTwoHundreddayMovingAverage PercentChangeFromTwoHundreddayMovingAverage ChangeFromFiftydayMovingAverage PercentChangeFromFiftydayMovingAverage Name Notes Open PreviousClose PricePaid ChangeinPercent PriceSales PriceBook ExDividendDate PERatio DividendPayDate PERatioRealtime PEGRatio PriceEPSEstimateCurrentYear PriceEPSEstimateNextYear Symbol SharesOwned ShortRatio LastTradeTime TickerTrend OneyrTargetPrice Volume HoldingsValue HoldingsValueRealtime YearRange DaysValueChange DaysValueChangeRealtime StockExchange DividendYield PercentChange ErrorIndicationreturnedforsymbolchangedinvalid Date Open High Low Close AdjClose)

    FIELDS.each do |field|
      __send__(:attr_accessor, to_underscore(field).to_sym)
    end

    def self.fields
      FIELDS
    end

    def self.quote(symbol, start_date = nil, end_date = nil, select = '*', format = 'instance')
      url = nil
      select = format_select(select, FIELDS)
      if start_date && end_date
        url = URI.encode("SELECT #{ select } FROM yahoo.finance.historicaldata WHERE symbol IN (#{to_p(symbol)}) AND startDate = '#{start_date}' AND endDate = '#{end_date}'")
      else
        url = URI.encode("SELECT #{ select } FROM yahoo.finance.quotes WHERE symbol IN (#{to_p(symbol)})")
      end

      request_query(format, symbol, url)
    end

    def self.json_quote(symbol, start_date = nil, end_date = nil, select = '*', format = 'json')
      quote(symbol, start_date, end_date, select, format)
    end

    def self.simple_return(symbol, start_date = Date.parse('2012-01-01'), end_date = Date.today)
      start, finish = to_date(start_date), to_date(end_date)
      raise ArgumentError.new('start dt after end dt') if start > finish

      quotes = []
      begin
        year_quotes = quote(
            symbol,
            start,
            min_date(finish, start + 365),
            'Close'
        )
        if year_quotes.is_a?(Array)
          quotes += year_quotes
        else
          return 0
        end
        start += 365
      end until finish - start < 365
      quotes
      sell = quotes.first.close
      buy = quotes.last.close
      ((sell - buy) / buy) * 100
    end

    def self.parse(json, symbol, format='instance')
      results = []
      json = JSON.parse(json).fetch('query')
      count = json['count']
      raise NoDataForStockError.new(json) if count == 0
      return json['results'] if !!(format=='json')

      data = json['results']['quote']
      data = count == 1 ? [data] : data
      data.each do |d|
        d['symbol'] = to_p(symbol) unless d['symbol']
        stock = Quotes.new(d)
        return stock if count == 1
        results << stock
      end

      results
    end

    def self.history(symbol, start_date = '2012-01-01', end_date = Date.today, select = '*', format = 'instance')
      start, finish = to_date(start_date), to_date(end_date)
      raise ArgumentError.new('start dt after end dt') if start > finish

      quotes = []
      begin
        quote = quote(symbol, start, min_date(finish, start + 365), select, format)
        quotes += !!(format=='json') ? quote['quote'] : Array(quote)
        start += 365
      end until finish - start < 365
      return !!(format=='json') ? {'quote' => quotes} : quotes

    rescue NoDataForStockError => e
      return e
    end

    def self.json_history(symbol, start_date = '2012-01-01', end_date = Date.today, select = '*', format = 'json')
      history(symbol, start_date, end_date, select, format)
    end
  end
end
