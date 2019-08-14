global.Ajv = require('ajv');
global.AjvSchema4 = require('ajv/lib/refs/json-schema-draft-04.json');
global.AjvSchema6 = require('ajv/lib/refs/json-schema-draft-06.json');

global.imjv = require('is-my-json-valid');

// Storage for validators so we can interact with them from R
global.validators = {"imjv": {}, "ajv": {}}

global.ajv_create_object = function(meta_schema_version) {
    if (meta_schema_version === "draft-04") {
        var opts = {meta: false,
                    schemaId: 'id',
                    allErrors: true,
                    verbose: true};
        return new Ajv(opts)
            .addMetaSchema(AjvSchema4)
            .removeKeyword('propertyNames')
            .removeKeyword('contains')
            .removeKeyword('const')
            .removeKeyword('if')
            .removeKeyword('then')
            .removeKeyword('else');
    } else {
        var opts = {allErrors: true, verbose: true};
        var ret = new Ajv({allErrors: true, verbose: true});
        if (meta_schema_version === "draft-06") {
            ret.addMetaSchema(AjvSchema6);
        }
        return ret;
    }
}

// TODO: we can push greedy into here
global.ajv_create = function(key, meta_schema_version, schema, dependencies,
                             reference) {
    var ret = ajv_create_object(meta_schema_version);

    if (dependencies) {
        dependencies.forEach(
            function(x) {ret.addSchema(drop_id(x.value), x.id)});
    }

    if (reference === null) {
        ret = ret.compile(schema);
    } else {
        ret = ret.addSchema(schema).getSchema(reference);
    }
    validators["ajv"][key] = ret;
}

global.drop_id = function(x) {
    delete x.id;
    delete x.$id;
    return x;
}

global.imjv_create = function(key, meta_schema_version, schema) {
    // https://github.com/mafintosh/is-my-json-valid/issues/160
    if (meta_schema_version != "draft-04") {
        throw new Error("Only draft-04 json schema is supported");
    }
    var ret = imjv(schema);
    validators["imjv"][key] = ret;
}

global.ajv_call = function(key, value, errors) {
    var validator = validators["ajv"][key];
    var success = validator(value);
    var errors = (!success && errors ? validator.errors : null);
    return {"success": success, "errors": errors, "engine": "ajv"};
}

global.imjv_call = function(key, value, errors, greedy) {
    var validator = validators["imjv"][key];
    var success = validator(value, {"greedy": greedy}, {"verbose": errors});
    var errors = (!success && errors ? validator.errors : null);
    return {"success": success, "errors": errors, "engine": "imjv"};
}

global.validator_delete = function(type, name) {
    delete validators[type][name];
}

global.get_meta_schema_version = function(schema) {
    return schema.$schema;
};

global.validator_stats = function() {
    return {"imjv": Object.keys(validators["imjv"]).length,
            "ajv": Object.keys(validators["ajv"]).length};
}

global.find_reference = function(x) {
    deps = []

    f = function(x) {
        if (Array.isArray(x)) {
            // need to descend into arrays as they're used for things
            // like oneOf or anyOf constructs.
            x.forEach(f);
        } else if (typeof(x) === "object") {
            // From the JSON schema docs:
            //
            // > You will always use $ref as the only key in an
            // > object: any other keys you put there will be ignored
            // > by the validator
            //
            // though this turns not to be true empirically...
            if ("$ref" in x) {
                deps.push(x["$ref"]);
            }
            // Would be nicer with Object.values but that does not
            // work on travis apparently.
            Object.keys(x).forEach(function(k) {f(x[k]);});
        }
    }
    f(x);
    return deps;
}
