# jsonvalidate

[![Build Status](https://travis-ci.org/ropensci/jsonvalidate.svg?branch=master)](https://travis-ci.org/ropensci/jsonvalidate)

Validate JSON against a schema using [`is-my-json-valid`](https://github.com/mafintosh/is-my-json-valid).  This package is simply a thin wrapper around the node library, using the [V8](http://cran.r-project.org/package=V8) package to call `is-my-json-valid` from R.

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

 Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[![ropensci_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
