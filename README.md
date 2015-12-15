[![Build Status](https://travis-ci.com/Acornsgrow/rack-request_auditing.svg?token=j8fT5VPY65oQ5xziayzW)](https://travis-ci.com/Acornsgrow/rack-request_auditing)
[![Code Climate](https://codeclimate.com/repos/5667214ffe3d9f4149000a46/badges/8d2bac957ba7d9f47eca/gpa.svg)](https://codeclimate.com/repos/5667214ffe3d9f4149000a46/feed)

# Rack::RequestAuditing

RequestAuditing is a gem that provides rack middleware for generating and
propagating request and correlation ids.

## Installation

Add this line to your application's Gemfile with your desired version number.
Be sure to have our gem source set correctly to [gemfury.com](https://gemfury.com)'s settings.

```ruby
gem 'rack-request_auditing', '~> 0.1'
```

And then execute:

```bash
$ bundle install
```

## Usage

Add `rack-request_auditing` to your middleware stack.

The Rack environment variables `HTTP_CORRELATION_ID` and `HTTP_CORRELATION_ID`
will be set in the request.  The http headers `Request-Id` and `Correlation-Id`
will be set in the response.

#### Rack app

```ruby
# config.ru
require 'rack/request_auditing'

use Rack::RequestAuditing
run YourApp
```

#### Lotus

You can read about rack middleware in their [guide](http://lotusrb.org/guides/actions/rack-integration/).

In `config.ru`, same as a [Rack app](#rack-app).

The [guide](http://lotusrb.org/guides/actions/request-and-response) recommends
accessing environment variables using `params.env`.  Access the request id with
`params.env["HTTP_REQUEST_ID"]` and the correlation id with
`params.env["HTTP_CORRELATION_ID"]`.

#### Rails

You can read about rails middleware in their [guide](http://guides.rubyonrails.org/rails_on_rack.html).

```ruby
# config/application.rb
config.middleware.use Rack::RequestAuditing
```

## Logging

A logger may be provided in the options hash as a second argument.

```ruby
# config.ru
use Rack::RequestAuditing, logger: Logger.new(STDOUT)
```

When this option is not provided, a `STDOUT` logger instance will be created.

The logger formatter will be set to an instance of
`Rack::RequestAuditing::LogFormatter`.  This formatter will produce logs tagged
with the correlation, request, and parent request id values.

The logger will be available as the global `Rack::RequestAuditing.logger`.

For example, `Rack::RequestAuditing.logger.info("foo")` will produce:

`2015-12-14 15:24:08,623 [] INFO foo {correlation_id="79253bac5fc8585c"} {request_id="56c75fa710fe6552"} {parent_request_id=null}`

When a value is not available, it will be logged as `null`.

The utility method `Rack::RequestAuditing.log_typed_event` is available for
logging with types (`:sr`, `:ss`, `:cs`, `:cr`).

`Rack::RequestAuditing.log_typed_event('Client Send', :cs)` produces:

`2015-12-14 15:24:08,655 [] INFO Client Send {type="cs"} {correlation_id="79253bac5fc8585c"} {request_id="af32fcbf5c974e08"} {parent_request_id="56c75fa710fe6552"}`

If your application has its own formatter, the context is globally accessible as
`Rack::RequestAuditing::ContextSingleton.context`.  This context object has the
accessors `correlation_id`, `request_id`, and `parent_request_id`.

When building a client, use `Rack::RequestAuditing::ContextSingleton.set_client_context`
to set the global client context and `Rack::RequestAuditing::ContextSingleton.unset_client_context`
to unset the global client context.

### HTTPClient example
```
require 'rack/request_auditing'
require 'httpclient'

class AuditedClient < HTTPClient
  class ContextFilter
    CORRELATION_ID_HEADER = 'Correlation-Id'
    REQUEST_ID_HEADER = 'Request-Id'
    PARENT_REQUEST_ID_HEADER = 'Parent-Request-Id'

    def initialize(client)
      @client = client
    end

    def filter_request(req)
      Rack::RequestAuditing::ContextSingleton.set_client_context
      Rack::RequestAuditing::ContextSingleton.correlation_id = req.header[CORRELATION_ID_HEADER].first
      Rack::RequestAuditing::ContextSingleton.request_id = req.header[REQUEST_ID_HEADER].first
      Rack::RequestAuditing::ContextSingleton.parent_request_id = req.header[PARENT_REQUEST_ID_HEADER].first
      Rack::RequestAuditing.log_typed_event('Client Send', :cs)
    end

    def filter_response(req, res)
      Rack::RequestAuditing.log_typed_event('Client Receive', :cr)
      Rack::RequestAuditing::ContextSingleton.unset_client_context
    end
  end

  def initialize(*args)
    super
    @header_filter = ContextFilter.new(self)
    @request_filter << @header_filter
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests.

#### Releasing a new version

- Update the version number in `version.rb`.
- Create a git tag for that version.
- Push git commits and tags.
- Run `gem build rack-request_auditing.gemspec`.
- Push the created `.gem` file to [gemfury.com](https://gemfury.com).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Acornsgrow/rack-request_auditing.
