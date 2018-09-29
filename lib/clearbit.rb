module Clearbit
  COMPANY_ENDPOINT = 'https://company.clearbit.com/v1/domains/find'.freeze

  class Error < StandardError; end

  class Client
    def initialize(api_key)
      @api_key = api_key
    end

    def company(company_name)
      begin
        result = http_client.get do |req|
          req.url COMPANY_ENDPOINT
          req.options.timeout = 2
          req.options.open_timeout = 1
          req.params['name'] = normalize_company_name(company_name)
        end
        JSON.parse(result.body)
      rescue => e
        # TODO log/raise to exception service (Rollbar, Sentry, etc.)
        raise ::Clearbit::Error, "Received an error from Clearbit: #{e.message}"
      end
    end

    private

    # Set up an HTTP Client that retries twice on errors w/ exponential backoff.
    # The backup/retries is why we use Faraday instead of open-uri.
    def http_client
      @conn ||= Faraday.new do |conn|
        conn.request :retry, max: 2, interval: 0.05,
                     interval_randomness: 0.5, backoff_factor: 2,
                     exceptions: ['Timeout::Error', 'Faraday::ClientError']
        conn.basic_auth(@api_key, '')
        conn.adapter  Faraday.default_adapter
      end
    end

    # Clearbit's API wants the company name to be an exact match. Sometimes we
    # need to do a little cleanup of what we get in the transaction record, like
    # remove a trailing "LLC" or "Inc" from the end of the name.
    def normalize_company_name(name)
      # cheats
      return 'Uber' if name.match /Uber [0-9]{6}.*/
      return 'Hulu' if name.match /.*?HULU.COM\/BILL$/

      # strip suffixes
      name
        .gsub(/[^A-Za-z0-9\,\s]/, '')
        .gsub(/Inc$/i, '')
        .gsub(/LLC$/i, '')
        .gsub(/gmbh$/i, '')
        .gsub(/\s*?nv$/i, '')
        .gsub(/\s*?ug$/i, '')
        .gsub(/\s*?ug$/i, '')
        .gsub(/s\ltd$/i, '')
        .gsub(/s\llp$/i, '')
        .gsub(/\,\s*?$/, '')
        .strip
    end
  end
end
