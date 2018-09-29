require File.dirname(__FILE__) + '/../spec_helper.rb'

describe 'Clearbit Client Library' do
  let(:client) { Clearbit::Client.new('sk_api-key') }
  let(:good_result) do
    {
      "company" => "Elvis",
      "domain" => "example.com",
      "logo" => "http://company.clearbit.com/elvis.png"
    }.to_json
  end

  before do
    stub_request(:get, /company.clearbit.com\/v1\/domains\/find/).to_return(body: good_result)
  end

  describe '#company' do
    it "makes a request from Clearbit's company endpoint" do
      client.company('elvis')
      expect(WebMock).to have_requested(:get, 'https://company.clearbit.com/v1/domains/find')
        .with(query: { name: 'elvis' })
    end

    it 'strips corp abbreviations from the end of the company name' do
      client.company('elvis inc')
      expect(WebMock).to have_requested(:get, 'https://company.clearbit.com/v1/domains/find?name=elvis')
    end
  end
end
