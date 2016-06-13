# jsonvalidate

[![Build Status](https://travis-ci.org/ropenscilabs/jsonvalidate.svg?branch=master)](https://travis-ci.org/ropenscilabs/jsonvalidate)
[![Build status](https://ci.appveyor.com/api/projects/status/gx82a6tp9eigrl70/branch/master?svg=true)](https://ci.appveyor.com/project/richfitz/jsonvalidate/branch/master)

Validate JSON against a schema using [`is-my-json-valid`](https://github.com/mafintosh/is-my-json-valid).  This packagfe is simply a thin wrapper around the node library, using the [V8](http://cran.r-project.org/package=V8) package to call `is-my-json-valid` from R.

## Installation

```r
devtools::install_github("ropenscilabs/jsonvalidate")
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

[![ropensci_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
