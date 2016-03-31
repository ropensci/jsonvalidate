# jsonvalidate

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
