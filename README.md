# BothIsGood

This gem adds a module to include into classes, supplying a convenient, concise
way to implement multiple versions of the same method, and _run them both_. Then
you can still _use_ the old implementation, but get an alert or log message if
the new version ever produces a different result.

This is not a new concept; `scientist` pioneered the approach in 2016. But
scientist is moderately _heavy_, and takes significant effort to use, so I've
ended up implementing lightweight dual-implementation libraries multiple times;
this time I'm publishing it so I won't have to do so again later!

## Inline Invocation

The "simplest" way to use BothIsGood is 'inline' - no configuration object,
you just supply all of the needed options on the `implemented_twice` call in
place.

```ruby
include BothIsGood

def foo_one = implementation(details)
def foo_two = more_implementation(details)

# A minimal call. Note that with no global configuration this is not very
# valuable, since if the implementations disagree, there's no hook implemented
# to _tell you_ that.
implemented_twice(:foo, original: :foo_one, replacement: :foo_two)

# A complex call using all of the available options:
implemented_twice(
  :foo,
  original: :foo_one,
  replacement: :foo_two,
  rate: 0.01,
  switch: ->(ctx) { FeatureFlags.enabled?(:"enable_#{ctx.tag}") },
  comparator: ->(val_one, val_two) { Math.abs(val_one - val_two) < 0.01 },
  on_mismatch: ->(val_one, val_two) { LOGGER.warn("mismatch: #{val_one} | #{val_two}") },
  on_compare: ->(val_one, val_two) { LOGGER.warn("comparing #{val_one} to #{val_two}") },
  on_primary_error: ->(err, args) { LOGGER.warn("primary error #{err.class.name}") },
  on_secondary_error: ->(err, args) { LOGGER.warn("secondary error #{err.class.name}") },
  on_hook_error: ->(err) { LOGGER.warn("OH NO! #{err.class.name}: #{err.message}") }
)
```

The method takes these parameters:

* The (only) positional parameter is the name of the method it will implement.
  This _can_ match the `original:` or `replacement:` name (but not both),
  and if it does, `implemented_twice` will alias the existing method out of
  the way (to `_bothisgood_original_#{name}` or
  `_bothisgood_replacement_#{name}`).
* The `original:` parameter specifies a method name that will be called _and
  have its result used as the return value_ regardless of the comparison
  outcome. Errors from the original method are bubbled up as usual.
* The `replacement:` parameter specifies a method name that will be called for
  comparison's sake (though not necessarily every time). Errors raised from
  the replacement method are swallowed.
* The `rate:` parameter (default 1.0) specifies what fraction of the calls
  should bother evaluating the shadow implementation for comparison. If the
  implementation is costly (makes significant database calls, for example)
  and/or invoked frequently, you probably want a lower rate in production.
* The `switch:` parameter takes a callable with arity 0 or 1. When it returns
  a truthy value, the roles swap: replacement becomes the return value and
  original becomes the shadow (called at `rate` for comparison). Arity 1
  receives a `BothIsGood::Context::Switching` object, making it straightforward
  to drive from a feature-flag system. The context exposes `target_class`,
  `method_name`, `target_class_name`, `target_class_string` (underscored,
  like `"my_module/my_class"`), and `tag` (like `"my_mod/my_class--my_method"`)
* The `comparator:` parameter takes a callable, and yields two arguments to
  it (the results of the two implementations); its result is truthy or falsey.
  By default, comparison is done using `==`.
* The `on_mismatch:` parameter takes a callable (lambda or Proc generally).
  It supports arities 2, 3, and 4. The first two arguments are always the
  _primary_ result (the one being returned) and the _secondary_ result (the
  shadow). **When `switch` is active, these are `(replacement, original)`,
  not `(original, replacement)`.** Arity 3 also receives a names hash like
  `{primary: :foo_one, secondary: :foo_two}` reflecting the current role
  assignment. Arity 4 additionally receives the call args array before the
  names hash. It fires any time the results _differ_.
* The `on_compare:` parameter takes the same shaped argument, but fires any
  time both implementations are evaluated (every time unless `rate` is set).
* The `on_primary_error:` parameter takes a callable and yields 1, 2, or 3
  arguments: the StandardError rescued, the args supplied (as an array,
  potentially with a Hash at the end for kwargs), and the name of the primary
  method. The exception will be re-raised after handling. With `switch`
  active, "primary" is the replacement method.
* The `on_secondary_error:` parameter behaves identically (yielding the
  secondary method name), but secondary exceptions are _not_ re-raised.
  With `switch` active, "secondary" is the original method.
* The `on_hook_error:` parameter is a callable that will be yielded _one_
  parameter (the StandardError instance), and is invoked if an error is
  _raised_ during one of the other hooks. Those errors will be swallowed if
  `on_hook_error` is supplied (unless your hook re-raises!), and bubbled
  otherwise.

`implemented_twice` can additionally be called with three positional
parameters; the second is used as the `original` method name, and the third
as `replacement`. That means that, if you use a configuration object, you can
just:

```ruby
include BothIsGood

def foo_one = implementation(details)
def foo_two = more_implementation(details)

# defines `foo`, using `foo_one` as original and `foo_two` as replacement.
implemented_twice :foo, :foo_one, :foo_two
```

If called with _two_ positional parameters, the first is used as both the
final method name _and_ the original implementation.

```ruby
include BothIsGood

def foo = implementation(details)
def foo_two = more_implementation(details)

# Defines `foo`, using `foo` as original and `foo_two` as replacement.
# The original `foo` method is aliased to `_bothisgood_original_foo`.
implemented_twice :foo, :foo_two
```

## Configuration

All parameters aside from the positional, `original:`, and `replacement:` ones
can be configured globally, or onto a `BothIsGood::Configuration` object, to
avoid having to supply them constantly.

```ruby
# Global configuration
BothIsGood.configure do |config|
  config.rate = 0.5
  config.switch = ->(ctx) { FeatureFlags.enabled?(:"enable_#{ctx.tag}") }
  config.on_compare = ->(a, b) { LOGGER.puts "compared!" }
  config.on_hook_error = ->(e) { LOGGER.puts "bad -.-" }
end

# Local configuration - starting values are taken from the global config
MY_BIG_CONFIG = BothIsGood::Configuration.new
MY_BIG_CONFIG.rate = 0.7
MY_BIG_CONFIG.on_secondary_error = ->(e) { LOGGER.puts "No" }

module MyFoo
  include BothIsGood
  self.both_is_good_configure(MY_BIG_CONFIG)
end

# In-class configuration - starting values are taken from the global config,
# or the supplied config object if one is given.
module MyBar
  include BothIsGood
  self.both_is_good_configure(rate: 0.02)
end
```
