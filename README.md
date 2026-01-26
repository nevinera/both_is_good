# BothIsGood

This gem adds a module to include into classes, supplying a convenient, concise way
to implement multiple versions of the same method, and _run them both_. Then you can
still _use_ the old implementation, but get an alert or log message if the new version
ever produces a different result.

```ruby
include BothIsGood

def foo_one = implementation(details)
def foo_two = more_implementation(details)

implemented_twice(:foo, original: :foo_one, replacement: :foo_two, result: :original)

# or maybe, if you don't want to pay the cost _every_ time..

implemented_twice(:foo, original: :foo_one, replacement: :foo_two, result: :original, rate: 0.01)
```

## Configuration

This can be done with a Configuration singleton, but you can also make multiple configurations and
pass one into the method, if different teams use the gem in different ways.

```ruby
# on the singleton:
BothIsGood.configure do |config|
  config.on_mismatch do |method, implementations, values|
    MyLogger.warn "Method #{method} produced different results for #{implementations.join(' and ')}: #{values.to_json}"
  end

  config.default_rate = 0.05
end

# On a separate configuration:
MY_BIG_CONFIG = BothIsGood::Configuration.new do |config|
  config.default_rate = 1.0

  config.on_evaluated do |method, implementations, values|
    Metrics.track("both_is_good.#{method}.evaluated")
  end
end
```

When a `config:` parameter is supplied on an `implemented_twice` method, or
`self.both_is_good_config=` is called on the including class with a BothIsGood::Config
instance, that configuration will be used; otherwise the singleton configuration will be.

The options are available:

* `on_evaluated` - a block to execute when the supplied implementations are executed. Note that if
  a "rate" is applied, this will only fire when _both_ implementations are executed. The block will
  receive the name of the method, an array of implementation names, and an array of result values.
* `on_mismatch` - a block to execute when the supplied implementations are executed, and the results
  do not match. This block will likewise receive the name of the method, an array of implementation
  names, and an array of result values (which will differ).
* `default_rate` - Overrides the default `rate` value for calls that don't specify one (the default
  default-rate is 1.0).

## Usage

The primary usage is the `implemented_twice` method, exhibited above. It _requires_ an initial
positional argument (the name of the method it will define), and the `original` and `replacement`
named params. It accepts these arguments:

* `method_name` - the initial (positional) argument; what method is this going to define?
* `original`/`replacement` - the names of the two methods we will dispatch to. Note that they may
  not refer to the same method, but one of them (typically `original`) _can_ match `method_name` -
  BothIsGood will alias the existing method out of the way for you.
* `result` - `:original`, `:replacement`, or a callable (`:original` by default). Which of the
  calculated results will actually be returned as _the_ result? If this is a block, it will receive
  `self`, and should return a boolean meaning "should we use the new implementation?".
* `rate` - if the calculation is somewhat expensive, or run extremely frequently, we won't want
  to run both implementations _every_ time. We'll be confident enough if we confirm that they
  match on a random.. 10% of the executions, say. The "rate" is "what fraction of the time do we
  run both implementations and compare them?" - it must be a number from 0 to 1 (1 by default).
* `config` - nil, or an instance of BothIsGood::Configuration.

You can supply a configuration by calling `self.both_is_good_config = MY_BIG_CONFIG` in the class
(after including BothIsGood), and then every call defined on that class or its subclasses will
use that configuration by default instead of the BothIsGood singleton config.

There is a shorthand method available as well: `checked_implementation(:foo, :foo_new)` is
equivalent to `implemented_twice(:foo, original: :foo, replacement: :foo_new)` - it will evaluate
both (rate of the time), return the result from :foo, and trigger the configured hooks as
appropriate.
