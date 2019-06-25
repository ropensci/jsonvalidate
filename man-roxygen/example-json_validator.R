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

# Create a validator function
v <- jsonvalidate::json_validator(schema)

# Test if some (invalid) json conforms to the schema
v("{}", verbose = TRUE)

# Test if some (valid) json conforms to the schema
v('{
    "id": 1,
    "name": "A green door",
    "price": 12.50,
    "tags": ["home", "green"]
}')

# Using features from draft-06 or draft-07 requires the ajv engine:
schema <- "{
  '$schema': 'http://json-schema.org/draft-06/schema#',
  'type': 'object',
  'properties': {
    'a': {
      'const': 'foo'
    }
  }
}"

# Create the validator
v <- jsonvalidate::json_validator(schema, engine = "ajv")

# This confirms to the schema
v('{"a": "foo"}')

# But this does not
v('{"a": "bar"}')
