require 'stock_quote'
require 'spec_helper'

describe StockQuote::Quotes do
  describe 'quote' do
    context 'success' do
      describe 'single symbol' do

        @fields = StockQuote::Quotes::FIELDS

        use_vcr_cassette 'aapl'

        @fields.each do |field|
          it ".#{field}" do
            @quote = StockQuote::Quotes.quote('aapl')
            @quote.should respond_to(to_underscore(field).to_sym)
          end
        end

        it 'should use underscore getter method for the underscore instance variable' do
          @quote = StockQuote::Quotes.new({ 'AdjClose' => 123 })
          expect(@quote.adj_close).to eq(123)
        end

        it 'should result in a successful query with ' do
          @quote = StockQuote::Quotes.quote('aapl')
          @quote.response_code.should be_eql(200)
          @quote.should respond_to(:no_data_message)
          @quote.no_data_message.should be_nil
        end

        describe "should select specific fields" do
          it "as string" do
            @quote = StockQuote::Quotes.quote('aapl', nil, nil, 'Symbol,Ask,Bid')
            @quote.response_code.should be_eql(200)
            @quote.should respond_to(:no_data_message)
            @quote.no_data_message.should be_nil
          end

          it "as array" do
            @quote = StockQuote::Quotes.quote('aapl', nil, nil, ['Symbol','Ask','Bid'])
            @quote.response_code.should be_eql(200)
            @quote.should respond_to(:no_data_message)
            @quote.no_data_message.should be_nil
          end
        end
      end
    end

    describe 'comma seperated symbols' do

      use_vcr_cassette 'aapl,tsla'

      it 'should result in a successful query' do
        @quotes = StockQuote::Quotes.quote('aapl,tsla')
        @quotes.each do |stock|
          stock.response_code.should be_eql(200)
          stock.should respond_to(:no_data_message)
          stock.no_data_message.should be_nil
        end
      end
    end

    context 'failure' do

      @fields = StockQuote::Quotes::FIELDS

      use_vcr_cassette 'asdf'

      it 'should fail... gracefully if no data is found for that ticker' do
        @quote = StockQuote::Quotes.quote('asdf')
        @quote.response_code.should be_eql(404)
        @quote.should respond_to(:no_data_message)
        @quote.no_data_message.should_not be_nil
      end

      it 'should fail... gracefully if the request errors out' do
        stock = StockQuote::Quotes.quote('\/')
        expect(stock.response_code).to eql(404)
        expect(stock).to be_instance_of(StockQuote::NoDataForStockError)
      end
    end
  end

  describe 'history' do
    context 'success' do
      use_vcr_cassette 'aapl_history'

      it 'should result in a successful query' do
        @quote = StockQuote::Quotes.history('aapl', Date.today - 20)
        @quote.count.should >= 1
      end

      it 'succesfuly queries history by default (no start date given' do
        @quote = StockQuote::Quotes.history('aapl')
        expect(@quote.count).to be >= 1
      end

      it 'succesfuly queries history by default (no start date given' do
        @quote = StockQuote::Quotes.history(
          'aapl',
          Date.parse('20130103'),
          Date.parse('20130103')
        )
        expect(@quote.count).to be == 1
      end
    end

    context 'failure' do
      use_vcr_cassette 'asdf_history'

      it 'should not result in a successful query' do
        stock = StockQuote::Quotes.history('asdf')
        expect(stock.response_code).to eq(404)
        expect(stock).to respond_to(:no_data_message)
        expect(stock.no_data_message).not_to be_nil
      end

      it 'should raise ArgumentError if start date is after end date' do
        expect do
          s = StockQuote::Quotes.history('aapl', Date.today + 2, Date.today)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe 'json' do
    context 'success' do
      describe 'single symbol' do

        use_vcr_cassette 'aapl'

        it "it should return json" do
          @quote = StockQuote::Quotes.json_quote('aapl')
          @quote.is_a?(Hash).should be_true
          @quote.should include('quote')
        end

        describe "should select specific fields" do
          it "as string" do
            @quote = StockQuote::Quotes.json_quote('aapl', nil, nil, 'Symbol,Ask,Bid')
            @quote.is_a?(Hash).should be_true
            @quote.should include('quote')
          end

          it "as array" do
            @quote = StockQuote::Quotes.json_quote('aapl', nil, nil, ['Symbol','Ask','Bid'])
            @quote.is_a?(Hash).should be_true
            @quote.should include('quote')
          end
        end
      end

      describe 'comma seperated symbols' do

        use_vcr_cassette 'aapl,tsla'

        it 'should result in a successful query' do
          @quotes = StockQuote::Quotes.json_quote('aapl,tsla')
          @quotes.is_a?(Hash).should be_true
          @quotes.should include('quote')
        end
      end
      describe 'history' do
        use_vcr_cassette 'aapl_history'

        it 'should result in a successful query' do
          @quote = StockQuote::Quotes.json_history('aapl', Date.today - 20)
          @quote.is_a?(Hash).should be_true
          @quote.should include('quote')
        end
      end
    end
  end

  describe 'simple_return' do
    context 'success' do
      use_vcr_cassette 'aapl_simple_return'

      it 'should result in a successful query' do
        simple_return = StockQuote::Quotes.simple_return(
          'aapl',
          Date.parse('2012-01-03'),
          Date.parse('2012-01-20')
        )
        expect(simple_return).to eq(2.205578386790845)
      end

      it 'should return 0 if only one price is found' do
        simple_return = StockQuote::Quotes.simple_return(
          'TSTA',
          Date.parse('20130201'),
          Date.parse('20130501')
        )
        expect(simple_return).to eq(0)
      end
    end

    context 'failure' do
      use_vcr_cassette 'asdf_simple_return'

      it 'should not result in a successful query' do
        expect do
          stock = StockQuote::Quotes.simple_return(
            'asdf',
            Date.parse('2012-01-03'),
            Date.parse('2012-01-20')
          )
        end.to raise_exception
      end

      it 'should raise ArgumentError if start date is after end date' do
        expect do
          s = StockQuote::Quotes.simple_return('aapl', Date.today + 2, Date.today)
        end.to raise_error(ArgumentError)
      end
    end
  end
end
