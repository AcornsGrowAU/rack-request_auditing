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

The Rack environment variables `HTTP_CORRELATION_ID`, `HTTP_REQUEST_ID`, and
`HTTP_PARENT_REQUEST_ID` will be set in the request.  The http headers
`Correlation-Id` and `Request-Id` will be set in the response.  If present in
the request, `Parent-Request-Id` will be passed through the response headers as
well.

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
accessing environment variables using `params.env`.  Access the correlation id
with `params.env["HTTP_CORRELATION_ID"]`, the request id with
`params.env["HTTP_REQUEST_ID"]`, and the parent request id with
`params.env["HTTP_PARENT_REQUEST_ID"]`.  Alternatively, use the thread singleton
`Rack::RequestAuditing::ContextSingleton` (see Logging for details).

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

When this option is not provided, a `Rack::RequestAuditing::ContextLogger`
logger will be created to `STDOUT`.  This logger automatically includes the
server context in log messages and uses `Rack::RequestAuditing::LogFormatter`.
This formatter has the datetime format `%Y-%m-%d %H:%M:%S,%L` and the message
format `%{time} [%{progname}] %{severity} %{msg}\n`.

The logger will be available as the global `Rack::RequestAuditing.logger`.

For example, `Rack::RequestAuditing.logger.info("foo")` will produce:

`2015-12-14 15:24:08,623 [] INFO foo {correlation_id="79253bac5fc8585c"} {request_id="56c75fa710fe6552"} {parent_request_id=null}`

When a value is not available, it will be logged as `null`.

The utility method `Rack::RequestAuditing::MessageAnnotator.annotate(msg, tags)`
is available for annotating messages with tags in the same format used by
`Rack::RequestAuditing::ContextLogger`.

`Rack::RequestAuditing::MessageAnnotator.annotate("foo", { bar: "baz" })` produces:

`foo {bar=\"baz\"}"`

If your application logger has its own formatter, the context is globally
accessible as `Rack::RequestAuditing::ContextSingleton`.  This context object
has the accessors `correlation_id`, `request_id`, and `parent_request_id`.

Contexts have a helper method `create_child_context` that returns a new context
with a new `request_id`.  The `parent_request_id` of the child context is the
`request_id` of the original context.  Correlation id is also copied.

When implementing a client, ensure that the client context is logged
appropriately on request and response.

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

    def self.logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        logger.formatter = ::Rack::RequestAuditing::LogFormatter.new
      end
    end

    def filter_request(req)
      context = extract_context_from_request(req)
      contextual_log('Client Send', :cs, context)
    end

    def filter_response(req, res)
      context = extract_context_from_request(req)
      contextual_log('Client Receive', :cr, context)
    end

    def contextual_log(msg, type, context)
      message = contextual_annotate_with_type(msg, type, context)
      self.class.logger.info(message)
    end

    def contextual_annotate_with_type(msg, type, context)
      tags = {
        type: type,
        correlation_id: context[:correlation_id],
        request_id: context[:request_id],
        parent_request_id: context[:parent_request_id]
      }
      return Rack::RequestAuditing::MessageAnnotator.annotate(msg, tags)
    end

    def extract_context_from_request(req)
      context = {}
      context[:correlation_id] = req.header[CORRELATION_ID_HEADER].first
      context[:request_id] = req.header[REQUEST_ID_HEADER].first
      context[:parent_request_id] = req.header[PARENT_REQUEST_ID_HEADER].first
      return context
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
