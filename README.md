[![Test](https://github.com/orlon-pro/foxify/actions/workflows/main.yml/badge.svg)](https://github.com/orlon-pro/foxify/actions/workflows/main.yml)
[![Gem Version](https://badge.fury.io/rb/foxify.svg)](https://badge.fury.io/rb/foxify)

# Foxify

`foxify` is a gem which provides resumable digest implementations in ruby by
leveraging the power of [Go](https://go.dev/)

The classes `Foxify::ResumableSHA256` and `Foxify::ResumableSHA1` can be safely
serialized and restored at any point in time and digest calculation can be resumed.
This is an advantage in stateless application servers where i.e. large files are
uploaded in chunks and you want to resume digest calculation in each request.

## Requirements

* Ruby 3.3+
* Go 1.23+

## Installation

Add the foxify gem to your Gemfile:

```text
gem "foxify"
```

Update your bundle:

```sh
bundle install
```

**NOTE**: You need a go-lang compiler version 1.23+ in your environment to compile the native part of this gem.

## Usage

### Foxify::ResumableSHA256

Simple usage without serializing:

```ruby
require 'foxify'

digest = Foxify::ResumableSHA256.new
digest.update("The quick brown fox jumps over the lazy dog")
digest.hexdigest # returns "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
```

Usage with serializing and resuming later on:

```ruby
require 'foxify'

digest = Foxify::ResumableSHA256.new
digest.update("The quick brown fox ")
data = digest.to_msgpack

# store data somewhere and later reload it
restored = Foxify::ResumableSHA256.from_msgpack(data)
restored.update("jumps over the lazy dog")
restored.hexdigest # returns "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
```

### Foxify::ResumableSHA1

Simple usage without serializing:

```ruby
require 'foxify'

digest = Foxify::ResumableSHA1.new
digest.update("The quick brown fox jumps over the lazy dog")
digest.hexdigest # returns "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"
```

Usage with serializing and resuming later on:

```ruby
require 'foxify'

digest = Foxify::ResumableSHA1.new
digest.update("The quick brown fox ")
data = digest.to_msgpack

# store data somewhere and later reload it
restored = Foxify::ResumableSHA1.from_msgpack(data)
restored.update("jumps over the lazy dog")
restored.hexdigest # returns "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/orlon-pro/foxify.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
