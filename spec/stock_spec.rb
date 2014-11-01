require 'stock_quote'
require 'spec_helper'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/vcr_cassettes/stock'
end

describe StockQuote::Stock do

  describe 'stock' do

    vcr_options = {cassette_name: 'aapl'}
    context 'success', vcr: vcr_options do

      @fields = StockQuote::Stock::FIELDS

      @fields.each do |field|
        it ".#{field}" do
          @stock = StockQuote::Stock.stock('aapl')
          @stock.should respond_to(to_underscore(field).to_sym)
        end
      end

      it 'should use underscore getter method for the underscore instance variable' do
        @stock = StockQuote::Stock.new({'FullTimeEmployees' => 123})
        expect(@stock.full_time_employees).to eq(123)
      end

      it 'should result in a successful query with ' do
        @stock = StockQuote::Stock.stock('aapl')
        @stock.response_code.should be_eql(200)
        @stock.should respond_to(:no_data_message)
        @stock.no_data_message.should be_nil
      end

    end

  end

end
