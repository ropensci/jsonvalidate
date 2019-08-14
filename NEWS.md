## jsonvalidate 1.?.?

* JSON can be validated against a subschema (#18, #19, @AliciaSchep)
* Validation with `error = TRUE` now returns `TRUE` (not `NULL)` on success
* Schemas can span multiple files, being included via `"$ref": "filename.json"` - supported with the ajv engine only (#20, #21, @r-ash).

## jsonvalidate 1.1.0

* Add support for JSON schema draft 06 and 07 using the [`ajv`](https://github.com/epoberezkin/ajv) node library.  This must be used by passing the `engine` argument to `json_validate` and `json_validator` at present (#2, #11, #15, #16, #17, @karawoo & @ijlyttle)

## jsonvalidate 1.0.1

* Initial CRAN release
