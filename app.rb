require 'date'
require 'json'
require 'plaid'
require 'sinatra'
require File.dirname(__FILE__) + '/lib/clearbit'
require File.dirname(__FILE__) + '/lib/financial'

set :public_folder, File.dirname(__FILE__) + '/static'
# set :port, ENV['PLAID_ENV'] || 4567

access_token = nil

get '/' do
  erb :index
end

post '/access_token' do
  begin
    response = plaid_client.access_token(params['public_token'])
    access_token = response['access_token']

    content_type :json
    response.to_json
  rescue Financial::Error => e
    error_response = format_error(e)

    content_type :json
    status 422
    error_response.to_json
  end
end

delete '/access_token' do
  begin
    response = plaid_client.delete_item(access_token)

    content_type :json
    response.to_json
  rescue Financial::Error => e
    error_response = format_error(e)

    content_type :json
    status 422
    error_response.to_json
  end
end

get '/transactions' do
  now = Date.today
  ninety_days_ago = (now - 90)

  begin
    response = plaid_client.transactions(access_token, ninety_days_ago, now)

    content_type :json
    { transactions: response }.to_json
  rescue Financial::Error => e
    error_response = format_error(e)

    content_type :json
    status 422
    error_response.to_json
  end
end

get '/company/:name' do
  begin
    content_type :json
    clearbit_client.company(params['name']).to_json
  rescue Clearbit::Error => e
    error_response = format_error(e)

    content_type :json
    status 422
    error_response.to_json
  end
end

error 500 do
  status 500
  { error: { error_code: "500", error_message: "Internal Server Error" } }.to_json
end

def plaid_client
  @plaid_client ||=
    Financial::PlaidClient.new(ENV['PLAID_ENV'],
                               ENV['PLAID_CLIENT_ID'],
                               ENV['PLAID_SECRET'],
                               ENV['PLAID_PUBLIC_KEY'])
end

def clearbit_client
  @clearbit_client ||=
    Clearbit::Client.new(ENV["CLEARBIT_API_KEY"])
end

def format_error(err)
  error_code = err.respond_to?(:error_code) ? err.error_code : nil
  { error: { error_code: error_code, error_message: err.message } }
end

def pretty_print_response(response)
  puts JSON.pretty_generate(response)
end
