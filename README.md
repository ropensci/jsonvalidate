# jsonvalidate

<!-- badges: start -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/ropensci/jsonvalidate.svg?branch=master)](https://travis-ci.org/ropensci/jsonvalidate)
[![codecov.io](https://codecov.io/github/ropensci/jsonvalidate/coverage.svg?branch=master)](https://codecov.io/github/ropensci/jsonvalidate?branch=master)
[![](http://www.r-pkg.org/badges/version/jsonvalidate)](https://cran.r-project.org/package=jsonvalidate)
<!-- badges: end -->


Validate JSON against a schema using [`is-my-json-valid`](https://github.com/mafintosh/is-my-json-valid) or [`ajv`](https://github.com/ajv-validator/ajv).  This package is a thin wrapper around these node libraries, using the [V8](https://cran.r-project.org/package=V8) package.

## Usage

Directly validate `json` against `schema`

```r
jsonvalidate::json_validate(json, schema)
```

or create a validator for multiple uses

```r
validate <- jsonvalidate::json_validator(schema)
validate(json)
validate(json2) # etc
```

See the [package vignette](https://docs.ropensci.org/jsonvalidate/articles/jsonvalidate.html) for complete examples.

## Installation

Install from CRAN with

```r
install.packages("jsonvalidate")
```

Alternatively, the current development version can be installed from GitHub with

```r
devtools::install_github("ropensci/jsonvalidate")
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/richfitz).

 Please note that this project is released with a [Contributor Code of Conduct](https://github.com/ropensci/jsonvalidate/blob/master/CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[![ropensci_footer](https://ropensci.org//public_images/github_footer.png)](https://ropensci.org/)
