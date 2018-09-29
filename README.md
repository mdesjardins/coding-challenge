# Coding Challenge

This implements a coding challenge for a job interview. It uses the Plaid API to download the transactions of an account for a financial institution, and uses the Clearbit API to populate the result with company domain names and logos. It also attempts to detect recurring charges by identifying charges about a month apart with the same name and transaction amount.

To run the application:
``` bash
git clone https://github.com/mdesjardins/coding-challenge.git
cd coding-challenge
```

## Install dependencies
`bundle`

## Start the app
```
PLAID_ENV=[sandbox|development] \
PLAID_CLIENT_ID='[CLIENT_ID]' \
PLAID_SECRET='[SECRET]' \
PLAID_PUBLIC_KEY='[PUBLIC_KEY]' \
ruby app.rb
```
and then go to http://localhost:4567. If you're doing development it's helpful to start the app with [rerun](https://github.com/alexch/rerun) to automatically restart the application when changes are made. Rerun is included in the Gemfile.

## Running the tests
All of the specs (both Ruby and Javascript based tests) are located in the `spec` directory.

### Ruby/RSpec based tests
Run `rspec` in the root directory.

### Javascript/Jest based tests
Before running the Javascript tests you'll need to make sure you have `npm` installed. `cd` into the `coding-challenge` directory and run

`npm install`

This will download and install all testing dependencies. To execute the tests, run `npm test`.

#### Enjoy!
