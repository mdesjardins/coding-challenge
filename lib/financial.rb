require 'plaid'

module Financial
  class Error < StandardError
    attr_reader :error_code
    def initialize(error_code)
      @error_code = error_code
    end
  end

  class PlaidClient
    def initialize(env, client_id, secret, public_key)
      @env = env
      @client_id = client_id
      @secret = secret
      @public_key = public_key
      @client = Plaid::Client.new(env: env,
                                  client_id: client_id,
                                  secret: secret,
                                  public_key: public_key)
    end

    # Exchange token flow - exchange a Link public_token for
    # an API access_token
    # https://plaid.com/docs/#exchange-token-flow
    def access_token(public_token)
      @client.item.public_token.exchange(public_token)
    end

    # deletes an item from our application. We need this
    # because items are a precious commodity with the developer
    # accounts, and we don't save the access_tokens for reuse
    # anywhere.
    def delete_item(access_token)
      @client.item.remove(access_token)
    end

    # Retrieve Transactions for an Item
    # https://plaid.com/docs/#transactions
    #
    # This method handles pagination internally and returns all results
    # in the requested date range.
    def transactions(access_token, start_date, end_date)
      product_response =
        @client.transactions.get(access_token, start_date, end_date)

      transactions = product_response.transactions
      while transactions.length < product_response['total_transactions']
        product_response =
          @client.transactions.get(access_token,
                                   start_date,
                                   end_date,
                                   offset: transactions.length)

        transactions += product_response.transactions
      end

      populate_recurring_flag(transactions)
    rescue ::Plaid::PlaidAPIError => e
      # TODO log/raise to exception service (Rollbar, Sentry, etc.)
      raise Financial::Error.new(e.error_code), "Received error from Plaid: #{e.error_message}"
    rescue ::Plaid::PlaidError => e
      # TODO log/raise to exception service (Rollbar, Sentry, etc.)
      raise Financial::Error.new(nil), "Received error from Plaid: #{e.message}"
    end

    private

    def populate_recurring_flag(transactions)
      # Create a collection of transaction dates that are
      # grouped by the name on the transaction.
      xactions = transactions
        .map { |xaction| xaction.merge("parsed_date" => Date.parse(xaction["date"])) }
        .map { |xaction| OpenStruct.new( 'name' => xaction['name'], 'date' => xaction['parsed_date'], 'amount' => xaction['amount'] ) }
        .group_by(&:name)

      # Only care if there's more than one.
      recurring = xactions.keep_if { |_name, xaction_group| xaction_group.length > 1 }

      # For each transaction grouped by name, if all of the transactions are about
      # a month apart, and they're all the same amount, call them recurring.
      monthly = recurring.keep_if do |_name, xactions_for_this_merchant|
        all_about_a_month_apart?(xactions_for_this_merchant.map(&:date)) &&
          all_same_amount?(xactions_for_this_merchant.map(&:amount))
      end

      merchant_with_recurring = monthly.keys

      transactions.each do |transaction|
        transaction["recurring"] = merchant_with_recurring.include?(transaction["name"])
      end

      transactions
    end

    def all_about_a_month_apart?(dates)
      days_apart = dates[0...-1].map.with_index { |_d, index| days_apart(dates[index], dates[index + 1]) }

      # We need the "about a month" fuzziness because of business days.
      less_than_a_month = 25
      more_than_a_month = 35
      days_apart.all? { |days| days > less_than_a_month && days < more_than_a_month }
    end

    def all_same_amount?(amounts)
      amounts.uniq.length == 1
    end

    def days_apart(recent_date, older_date)
      (recent_date - older_date).to_i
    end
  end
end
