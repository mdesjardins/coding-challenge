# spec/app_spec.rb
require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Clearbit Code Challenge App' do
  let(:plaid_client) { double('PlaidClient') }
  let(:clearbit_client) { double('ClearbitClient') }

  before do
    allow(Financial::PlaidClient).to receive(:new).and_return(plaid_client)
    allow(Clearbit::Client).to receive(:new).and_return(clearbit_client)
  end

  describe 'GET /' do
    it 'should allow accessing the home page' do
      get '/'
      expect(last_response).to be_ok
    end
  end

  describe 'POST /access_token' do
    context 'default case' do
      before do
        allow(plaid_client).to receive(:access_token).and_return({ 'access_token' => 'abc'})
        post '/access_token', { 'public_token' => '123' }
      end

      it 'should return 200 OK' do
        expect(last_response).to be_ok
      end

      it 'should invoke the access_token method on the plaid client' do
        expect(plaid_client).to have_received(:access_token).with('123')
      end

      it 'should return a JSON object that contains an access token' do
        result = JSON.parse(last_response.body)
        expect(result['access_token']).to eq 'abc'
      end
    end

    context 'plaid returns an API error' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(Financial::Error.new('elvis'))
        post '/access_token', { 'public_token' => '123' }
      end

      it 'it returns 422' do
        expect(last_response.status).to eq(422)
      end

      it 'returns an error code in the body' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_code']).to eq('elvis')
      end
    end

    context 'some other general error occurs' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(StandardError)
        post '/access_token', { 'public_token' => '123' }
      end

      it 'returns a 500' do
        expect(last_response.status).to eq(500)
      end

      it 'returns Internal Server Error as a message' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_message']).to eq 'Internal Server Error'
      end
    end
  end

  describe 'DELETE /access_token' do
    context 'default case' do
      before do
        allow(plaid_client).to receive(:delete_item).and_return({ 'removed' => true })
        delete '/access_token'
      end

      it 'should return 200 OK' do
        expect(last_response).to be_ok
      end

      it 'should invoke the delete_item method on the plaid client' do
        expect(plaid_client).to have_received(:delete_item)
      end

      it 'should return a JSON object that contains a removed flag' do
        result = JSON.parse(last_response.body)
        expect(result['removed']).to eq true
      end
    end

    context 'plaid returns an API error' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(Financial::Error.new('elvis'))
        post '/access_token', { 'public_token' => '123' }
      end

      it 'it returns 422' do
        expect(last_response.status).to eq(422)
      end

      it 'returns an error code in the body' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_code']).to eq('elvis')
      end
    end

    context 'some other general error occurs' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(StandardError)
        post '/access_token', { 'public_token' => '123' }
      end

      it 'returns a 500' do
        expect(last_response.status).to eq(500)
      end

      it 'returns Internal Server Error as a message' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_message']).to eq 'Internal Server Error'
      end
    end
  end

  describe 'GET /transactions' do
    context 'default case' do
      before do
        allow(plaid_client).to receive(:transactions).and_return(['abc'])
        get '/transactions'
      end

      it 'should return 200 OK' do
        expect(last_response).to be_ok
      end

      it 'should invoke the access_token method on the plaid client' do
        expect(plaid_client).to have_received(:transactions) #.with('123')
      end

      it 'should return a JSON object that contains an array of transactions' do
        result = JSON.parse(last_response.body)
        expect(result['transactions']).to eq ['abc']
      end
    end

    context 'plaid returns an API error' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(Financial::Error.new('elvis'))
        post '/access_token', { 'public_token' => '123' }
      end

      it 'it returns 422' do
        expect(last_response.status).to eq(422)
      end

      it 'returns an error code in the body' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_code']).to eq('elvis')
      end
    end

    context 'some other general error occurs' do
      before do
        allow(plaid_client).to receive(:access_token).and_raise(StandardError)
        post '/access_token', { 'public_token' => '123' }
      end

      it 'returns a 500' do
        expect(last_response.status).to eq(500)
      end

      it 'returns Internal Server Error as a message' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_message']).to eq 'Internal Server Error'
      end
    end
  end

  describe 'GET /company/:name' do
    before do
      allow(clearbit_client).to receive(:company).and_return( { name: "Company", domain: "example.com", logo: "http://www.clearbit.com/example.png" } )
      get '/company/example'
    end

    context 'default case' do
      it 'should return 200 OK' do
        expect(last_response).to be_ok
      end

      it 'should invoke the company method on the clearbit client' do
        expect(clearbit_client).to have_received(:company).with('example')
      end

      it 'should return a JSON object that contains the company name, domain, and logo' do
        result = JSON.parse(last_response.body)
        expect(result['name']).to eq('Company')
        expect(result['domain']).to eq('example.com')
        expect(result['logo']).to eq('http://www.clearbit.com/example.png')
      end
    end

    context 'clearbit returns an error' do
      before do
        allow(clearbit_client).to receive(:company).and_raise(Clearbit::Error)
        get '/company/example'
      end

      it 'it returns 422' do
        expect(last_response.status).to eq(422)
      end

      it 'returns an error message in the body' do
        result = JSON.parse(last_response.body)
        expect(result['error']['error_message']).to eq('Clearbit::Error')
      end
    end
  end
end
