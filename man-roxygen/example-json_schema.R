# A simple schema example:
schema <- '{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "Product",
    "description": "A product from Acme\'s catalog",
    "type": "object",
    "properties": {
        "id": {
            "description": "The unique identifier for a product",
            "type": "integer"
        },
        "name": {
            "description": "Name of the product",
            "type": "string"
        },
        "price": {
            "type": "number",
            "minimum": 0,
            "exclusiveMinimum": true
        },
        "tags": {
            "type": "array",
            "items": {
                "type": "string"
            },
            "minItems": 1,
            "uniqueItems": true
        }
    },
    "required": ["id", "name", "price"]
}'

# Construct a schema object
obj <- jsonvalidate::json_schema$new(schema)

# Test if some (invalid) json conforms to the schema
obj$validate("{}")

# Get a (rather verbose) explanation about why this was invalid:
obj$validate("{}", verbose = TRUE)

# Test if some (valid) json conforms to the schema
json <- '{
    "id": 1,
    "name": "A green door",
    "price": 12.50,
    "tags": ["home", "green"]
}'
obj$validate(json)

# The reverse; some R data that we want to serialise to conform with
# this schema
x <- list(id = 1, name = "apple", price = 0.50, tags = "fruit")

# Note that id, name, price are unboxed here (not arrays) but tags is
# a length-1 array
obj$serialise(x)
