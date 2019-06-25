# jsonvalidate

[![Build Status](https://travis-ci.org/ropensci/jsonvalidate.svg?branch=master)](https://travis-ci.org/ropensci/jsonvalidate)

Validate JSON against a schema using [`is-my-json-valid`](https://github.com/mafintosh/is-my-json-valid) or [`ajv`](https://github.com/epoberezkin/ajv).  This package is simply a thin wrapper around these node libraries, using the [V8](https://cran.r-project.org/package=V8) package.

## Installation

```r
devtools::install_github("ropensci/jsonvalidate")
```

## Usage

```r
jsonvalidate::validate_json(json, schema)
```

or

```r
validate <- jsonvalidate::validate_json(schema)
validate(json)
validate(json2) # etc
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/richfitz).

 Please note that this project is released with a [Contributor Code of Conduct](https://github.com/ropensci/jsonvalidate/blob/master/CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[![ropensci_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
