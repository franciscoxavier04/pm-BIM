---
title: OpenProject 16.2.0
sidebar_navigation:
    title: 16.2.0
release_version: 16.2.0
release_date: 2025-07-16
---

# OpenProject 16.2.0

Release date: 2025-07-16

TODO

## Important technical changes

### Breaking: Interface changes to BaseCallable and BaseContracted

The method signatures shared between `BaseServices::BaseCallable`, `BaseServices::BaseContracted` and their subclasses (this includes `BaseServices::Create` and `BaseServices::Update` among others) have been changed.
The method argument `params` was removed, to encourage consistently using the `params` attribute accessor instead. Previously it was
unclear whether using the argument or the accessor should be used, that should be more clear and consistent now.

For plugin developers this means that signatures of the following methods have to be updated accordingly,
if they are defined in a subclass of `BaseServices::BaseContracted`:

* `validate_params(params)` becomes `validate_params`
* `before_perform(params, call)` becomes `before_perform(call)`
* `after_validate(params, call)` becomes `after_validate(call)`

Subclasses of `BaseServices::BaseContracted` need to change `perform` if it previously only accepted keyword-arguments, which are not
passed to `perform` anymore. Positional arguments are still passed as before. Examples:

* `perform(params = {})` becomes `perform` (this is the case for all subclasses of `BaseContracted`)
* `perform(a, b:)` becomes `perform(a)`

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->
<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

TODO
