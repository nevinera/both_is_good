# Changelog

## 0.5.0

### Breaking changes

* All of the callables (except `on_hook_error`) are now passed a single
  "context" object exposing the available data, instead of being yielded
  complex lists of values depending on their arity. This also exposes
  some additional data to those hooks for use.

## 0.4.0

### Breaking changes

* `primary:` and `secondary:` are renamed to `original:` and `replacement:`
  throughout the public API.
* The internal alias prefixes change from
  `_bothisgood_primary_` / `_bothisgood_secondary_` to
  `_bothisgood_original_` / `_bothisgood_replacement_`.

### New features

* Added `switch:` parameter, for swapping the implementation based on
  feature-flags.

## 0.3.1

* Allow the supplied `original` / `replacement` methods to be private.
