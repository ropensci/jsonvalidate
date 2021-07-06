## jsonvalidate 1.3.0

* Upgrade to ajv version 8.5.0
* Add arg `strict` to `json_validate` and `json_validator` to allow evaluating schema in strict mode for ajv only. This is off (`FALSE`) by default to use permissive behaviour detailed in JSON schema

## jsonvalidate 1.2.3

* Schemas can use references to other files with JSON pointers i.e. schemas can reference parts of other files e.g. `definitions.json#/definitions/hello`
* JSON can be validated against a subschema (#18, #19, @AliciaSchep)
* Validation with `error = TRUE` now returns `TRUE` (not `NULL)` on success
* Schemas can span multiple files, being included via `"$ref": "filename.json"` - supported with the ajv engine only (#20, #21, @r-ash).
* Validation can be performed against a fraction of the input data (#25)

## jsonvalidate 1.1.0

* Add support for JSON schema draft 06 and 07 using the [`ajv`](https://github.com/ajv-validator/ajv) node library.  This must be used by passing the `engine` argument to `json_validate` and `json_validator` at present (#2, #11, #15, #16, #17, @karawoo & @ijlyttle)

## jsonvalidate 1.0.1

* Initial CRAN release
