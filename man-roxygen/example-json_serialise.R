# This is the schema from ?json_validator
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

# We're going to use a validator object below
v <- jsonvalidate::json_validator(schema, "ajv")

# And this is some data that we might generate in R that we want to
# serialise using that schema
x <- list(id = 1, name = "apple", price = 0.50, tags = "fruit")

# If we serialise to json, then 'id', 'name' and "price' end up a
# length 1-arrays
jsonlite::toJSON(x)

# ...and that fails validation
v(jsonlite::toJSON(x))

# If we auto-unbox then 'fruit' ends up as a string and not an array,
# also failing validation:
jsonlite::toJSON(x, auto_unbox = TRUE)
v(jsonlite::toJSON(x, auto_unbox = TRUE))

# Using json_serialise we can guide the serialisation process using
# the schema:
jsonvalidate::json_serialise(x, v)

# ...and this way we do pass validation:
v(jsonvalidate::json_serialise(x, v))
