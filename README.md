# BothIsGood

This gem adds a module to include into classes, supplying a convenient, concise way
to implement multiple versions of the same method, and _run them both_. Then you
can still _use_ the old implementation, but get an alert or log message if the new
version ever produces a different result.

This is not a new concept; `scientist` pioneered the approach in 2016. But scientist
is moderately _heavy_, and takes significant effort to use, so I've ended up implementing
lightweight dual-implementation libraries multiple times; this time I'm publishing
it so I won't have to do so again later!

## Inline Invocation

The "simplest" way to use BothIsGood is 'inline' - no configuration object, you just
supply all of the needed options on the `implemented_twice` call in place.

```ruby
include BothIsGood

def foo_one = implementation(details)
def foo_two = more_implementation(details)

# A minimal call. Note that with no global configuration this is not very valuable,
# since if the implementations disagree, there's no hook implemented to _tell you_ that.
implemented_twice(:foo, original: :foo_one, replacement: :foo_two)

# A complex call using all of the available options:
implemented_twice(
  :foo,
  original: :foo_one,
  replacement: :foo_two,
  rate: 0.01,
  comparator: ->(val_one, val_two) { Math.abs(val_one - val_two) < 0.01 },
  on_mismatch: ->(val_one, val_two) { LOGGER.warn("result mismatch on Foo#foo_one vs Foo#foo_two: #{val_one} | #{val_two}") },
  on_compare: ->(val_one, val_two) { LOGGER.warn("comparing #{val_one} to #{val_two}") },
  on_primary_error: ->(err, args) { LOGGER.warn("calling foo_one with #{args.to_json} produced error #{err.class.name}") },
  on_secondary_error: ->(err, args) { LOGGER.warn("calling foo_two with #{args.to_json} produced error #{err.class.name}") },
  on_hook_error: ->(err) { LOGGER.warn("OH NO! #{err.class.name}: #{err.message}") }
)
```

The method takes these parameters:

* The (only) positional parameter is the name of the method it will implement.
  This _can_ match the `original:` or `replacement:` name (but not both, obviously),
  and if it does, `implemented_twice` will alias the existing method out of the
  way (to `_bothisgood_original_#{name}` or `_bothisgood_replacement_#{name}`).
* The `original:` parameter specifies a method name that will be called _and have
  its result used as the result of the final method_ regardless of the comparison
  outcome. Errors from the original method are bubbled up as usual.
* The `replacement:` parameter specifies a method name that will be called for
  comparison's sake (though not necessarily every time). Errors raised from the
  replacement method are swallowed.
* The `rate:` parameter (default 1.0) specifies what fraction of the calls should
  bother evaluating the replacement implementation for comparison. If the
  implementation is costly (makes significant database calls, for example) and/or
  invoked frequently, you probably want a lower rate, at least in production.
* The `comparator:` parameter takes a callable, and yields two arguments to it
  (the results of the two implementations); its result is either truthy or falsey.
  By default, comparison is done using `==`.
* The `on_mismatch:` parameter takes a callable (lambda or Proc generally). It will
  yield the two values being compared, but can yield additional details depending
  on the arity of the callable; arities 2, 3, and 4 are all supported, and will be
  yielded the arguments supplied, and then a Hash of the implementation method
  names like `{primary: :foo_one, secondary: :foo_two}`. It will be invoked any
  time the results of the two implementations _differ_.
* The `on_compare:` parameter takes the same shaped argument, but will be fired
  any time both implementations are evaluated (so every time, unless `rate` is set)
* The `on_primary_error:` parameter takes a callable and yields 1, 2, or 3
  arguments to it, depending on its arity - those arguments are the StandardError
  instance rescued, the args supplied to the implementation (as an array,
  potentially with a Hash arg at the end for any kwargs), and the name of the
  original method. The exception will be re-raised after handling.
* The `on_secondary_error:` parameter behaves identically (yielding the replacement
  method name), but replacement exceptions are _not_ re-raised.
* The `on_hook_error:` parameter is a callable that will be yielded _one_
  parameter (the StandardError instance), and is invoked if an error is _raised_
  during one of the other hooks. None of us write bug-free code, and the callbacks
  supplied to `implemented_twice` are no exception. Those errors will be swallowed
  if `on_hook_error` is supplied (unless your hook raises the error!), but will be
  bubbled otherwise.

`implemented_twice` can additionally be called with three positional parameters;
the second parameter is used as the `original` method name, and the third parameter
is used as the `replacement` method name. That means that, if you use a configuration
object, you can just:

```ruby
include BothIsGood

def foo_one = implementation(details)
def foo_two = more_implementation(details)

# defines `foo`, using `foo_one` as the original implementation and `foo_two` as replacement.
implemented_twice :foo, :foo_one, :foo_two
```

If it is called with _two_ positional parameters, it will use the first argument
as both the final method name _and_ the original implementation.

```ruby
include BothIsGood

def foo = implementation(details)
def foo_two = more_implementation(details)

# Defines `foo`, using `foo` as the original implementation and `foo_two` as replacement.
# In the process, the original `foo` method is aliased to `_bothisgood_original_foo`.
implemented_twice :foo, :foo_two
```

## Configuration

All of those parameters aside from the positional, `original:`, and `replacement:`
ones can be configured globally, or onto a BothIsGood::Configuration object, to
avoid having to supply them constantly.

```ruby
# Global configuration
BothIsGood.configure do |config|
  config.rate = 0.5
  config.on_compare = ->(a, b) { LOGGER.puts "compared!" }
  config.on_hook_error = ->(e) { LOGGER.puts "bad -.-" }
end

# Local configuration - starting values are taken from the global config
MY_BIG_CONFIG = BothIsGood::Configuration.new
MY_BIG_CONFIG.rate = 0.7
MY_BIG_CONFIG.on_secondary_error = ->(a, b) { LOGGER.puts "No" }

module MyFoo
  include BothIsGood
  self.both_is_good_configure(MY_BIG_CONFIG)
end


# In-class configuration - starting values are taken from the global config, or the
# supplied config object if one is given.
module MyBar
  include BothIsGood
  self.both_is_good_configure(rate: 0.02)
end
```
