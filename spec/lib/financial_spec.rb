require File.dirname(__FILE__) + '/../spec_helper.rb'

describe 'Plaid Client Library' do
  let(:client) { Financial::PlaidClient.new('sandbox', 'clientid', 'secret', 'public_key') }
  let(:plaid_client) { double('Plaid Client') }

  before do
    allow(Plaid::Client).to receive(:new).and_return(plaid_client)
  end

  describe '#access_token' do
    let(:public_token) { double('Public Token') }
    let(:item) { double('Item', public_token: public_token) }

    before do
      allow(plaid_client).to receive(:item).and_return(item)
      allow(public_token).to receive(:exchange)
    end

    it 'call the token exchange API' do
      client.access_token('public_token')
      expect(public_token).to have_received(:exchange)
    end
  end

  describe '#delete_item' do
    let(:public_token) { double('Public Token') }
    let(:item) { double('Item') }

    before do
      allow(plaid_client).to receive(:item).and_return(item)
      allow(item).to receive(:remove)
    end

    it 'should invoke the remove item API' do
      client.delete_item('access_token')
      expect(item).to have_received(:remove).with('access_token')
    end
  end

  describe '#transactions' do
    let(:transactions) { double("Transactions") }

    context "when there is no result" do
      let(:product_response) { double("Product Response", :[] => 0, transactions: []) }

      before do
        allow(plaid_client).to receive(:transactions).and_return(transactions)
        allow(transactions).to receive(:get).and_return(product_response)
      end

      it 'should invoke the get transactions api' do
        client.transactions('access_token', '2018-01-01', '2017-01-01')
        expect(transactions).to have_received(:get).with('access_token', '2018-01-01', '2017-01-01')
      end
    end

    context 'when results need to be paginated' do
      let(:first_transactions) do
        [
          { "name" => "ACME", "date" => "2018-01-01", "amount" => 123 },
          { "name" => "ACME", "date" => "2018-02-01", "amount" => 456 },
          { "name" => "ACME", "date" => "2018-03-01", "amount" => 789 },
        ]
      end
      let(:second_transactions) do
        [
          { "name" => "Elvis", "date" => "2018-01-01", "amount" => 123 },
          { "name" => "Elvis", "date" => "2018-02-01", "amount" => 456 },
          { "name" => "Elvis", "date" => "2018-03-01", "amount" => 789 },
        ]
      end

      let(:first_product_response) { double("Product Response", :[] => 6, transactions: first_transactions) }
      let(:second_product_response) { double("Product Response", :[] => 6, transactions: second_transactions) }
      before do
        allow(plaid_client).to receive(:transactions).and_return(transactions)
        allow(transactions).to receive(:get).and_return(first_product_response, second_product_response)
      end

      it 'should invoke the transaction get API twice' do
        client.transactions('access_token', '2018-01-01', '2017-01-01')
        expect(transactions).to have_received(:get).twice
      end

      it 'should invoke the transaction get API with an offset of 3 the second time it is called' do
        client.transactions('access_token', '2018-01-01', '2017-01-01')
        expect(transactions).to have_received(:get)
          .with('access_token', '2018-01-01', '2017-01-01')
        expect(transactions).to have_received(:get)
          .with('access_token', '2018-01-01', '2017-01-01', offset: 3)
      end
    end

    context 'when the Plaid API raises an exception' do
      let(:plaid_api_error) do
        Plaid::PlaidAPIError.new('type',
          'error_code', 'error_message', 'display_message', 'request_id')
      end

      before do
        allow(plaid_client).to receive(:transactions).and_raise(plaid_api_error)
      end

      it 'wraps the exception in its own exception' do
        expect { client.transactions('access_token', '2018-01-01', '2017-01-01') }
          .to raise_error(Financial::Error)
      end

      it 'sets the error message' do
        expect { client.transactions('access_token', '2018-01-01', '2017-01-01') }
          .to raise_error(Financial::Error).with_message(/Received error from Plaid: error_message/)
      end
    end
  end

  describe '#populate_recurring_flag' do
    it 'sets the recurring flag to true for charges about a month apart and the same name and amount' do
      transactions = [
        { 'name' => 'ACME', 'date' => '2018-12-01', 'amount' => 123 },
        { 'name' => 'ACME', 'date' => '2018-11-02', 'amount' => 123 },
        { 'name' => 'ACME', 'date' => '2018-10-03', 'amount' => 123 }, # these are recurring
        { 'name' => 'ABC',  'date' => '2018-12-01', 'amount' => 456 },
        { 'name' => 'ABC',  'date' => '2018-11-02', 'amount' => 789 }, # different amounts
        { 'name' => 'XYZ',  'date' => '2018-12-01', 'amount' => 999 },
        { 'name' => 'XYZ',  'date' => '2018-11-21', 'amount' => 999 }, # not a month apart
        { 'name' => 'FOO',  'date' => '2018-12-01', 'amount' => 111 }, # loner
      ]

      # I don't usually test private methods, but this one is kind of an exception.
      result = client.send(:populate_recurring_flag, transactions)
      expect(result).to eq([
        { 'name' => 'ACME', 'date' => '2018-12-01', 'amount' => 123, 'recurring' => true },
        { 'name' => 'ACME', 'date' => '2018-11-02', 'amount' => 123, 'recurring' => true },
        { 'name' => 'ACME', 'date' => '2018-10-03', 'amount' => 123, 'recurring' => true },
        { 'name' => 'ABC',  'date' => '2018-12-01', 'amount' => 456, 'recurring' => false },
        { 'name' => 'ABC',  'date' => '2018-11-02', 'amount' => 789, 'recurring' => false },
        { 'name' => 'XYZ',  'date' => '2018-12-01', 'amount' => 999, 'recurring' => false },
        { 'name' => 'XYZ',  'date' => '2018-11-21', 'amount' => 999, 'recurring' => false },
        { 'name' => 'FOO',  'date' => '2018-12-01', 'amount' => 111, 'recurring' => false },
        ]
      )
    end
  end
end
