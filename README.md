# jsonvalidate

[![Build Status](https://travis-ci.org/ropenscilabs/jsonvalidate.svg?branch=master)](https://travis-ci.org/ropenscilabs/jsonvalidate)
[![Build status](https://ci.appveyor.com/api/projects/status/gx82a6tp9eigrl70/branch/master?svg=true)](https://ci.appveyor.com/project/richfitz/jsonvalidate/branch/master)

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
