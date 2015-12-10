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

The logger instance will be extended with `RequestAuditing::AuditLogging` and
made available in the rack environment as `rack.header`.  Logging with
this instance will produce logs tagged with the correlation, request, and parent
id values.

For example, `env["rack.header"].info("foo")` will produce:
`2015-12-09 18:06:11,002 [] INFO foo - correlation_id="9d9ea84356799aac", request_id="07dce5aafdcf2731", parent_id=null`

When a value is not available, it will be logged as `null`.

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
