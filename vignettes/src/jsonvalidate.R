## ---
## title: "jsonvalidate"
## author: "Rich FitzJohn"
## date: "`r Sys.Date()`"
## output: rmarkdown::html_vignette
## vignette: >
##   %\VignetteIndexEntry{jsonvalidate}
##   %\VignetteEngine{knitr::rmarkdown}
##   %\VignetteEncoding{UTF-8}
## ---

## This package wraps [is-my-json-valid](https://github.com/mafintosh/is-my-json-valid) using [V8](https://cran.r-project.org/package=V8) to do JSON schema validation in R.

## You need a JSON schema file; see
## [json-schema.org](http://json-schema.org) for details on writing
## these.

## As an example, here is a schema for an object that requires a
## "hello" field that is a string:

## ```json
## {
##     "required": true,
##     "type": "object",
##     "properties": {
##         "hello": {
##             "required": true,
##             "type": "string"
##         }
##     }
## }
## ```

## We can create a validator with:
v <- jsonvalidate::json_validator('{
    "required": true,
    "type": "object",
    "properties": {
        "hello": {
            "required": true,
            "type": "string"
        }
    }
}')

## (the argument here can also be a filename).

## The returned object is a function that takes as its first argument
## a json string, or a filename of a json file.  The empty list will
## fail validation because it does not contain a "hello" element:
v("{}")

## To get more information on why the validation fails, add `verbose=TRUE`:
v("{}", verbose=TRUE)

## The attribute "errors" is a data.frame and is present only when the
## json fails validation.

## Alternatively, to throw an error if the json does not validate, add
## `error=TRUE`:
##+ error=TRUE
v("{}", error=TRUE)

## If the JSON _is_ valid, then we have:
v("{hello: 'world'}")
v("{hello: 'world'}", verbose=TRUE)
v("{hello: 'world'}", error=TRUE)
