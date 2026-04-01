# Changelog

## 0.4.0 (unreleased)

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
