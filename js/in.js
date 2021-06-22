global.Ajv = require('ajv');
global.AjvSchema4 = require('ajv-draft-04');
global.AjvSchema6 = require('ajv/dist/refs/json-schema-draft-06.json');
global.addFormats = require('ajv-formats');

global.imjv = require('is-my-json-valid');

// Storage for validators so we can interact with them from R
global.validators = {"imjv": {}, "ajv": {}};

global.ajv_create_object = function(meta_schema_version, strict) {
    // Need to disable strict mode, otherwise we get warnings
    // about unknown schema entries in draft-04 (e.g., presence of
    // const) and draft-07 (e.g. presence of "reference")
    var opts = {allErrors: true, verbose: true, strict: strict};
    if (meta_schema_version === "draft-04") {
        // Need to drop keywords present in later schema versions,
        // otherwise they seem to be not ignored (e.g., a schema that
        // has the 'const' keyword will check it, even though that
        // keyword is not part of draft-04)
        var ret = new AjvSchema4(opts)
            .removeKeyword('propertyNames')
            .removeKeyword('contains')
            .removeKeyword('const')
            .removeKeyword('if')
            .removeKeyword('then')
            .removeKeyword('else');
    } else {
        var ret = new Ajv(opts);
        if (meta_schema_version === "draft-06") {
            ret.addMetaSchema(AjvSchema6);
        }
    }
    addFormats(ret);
    return ret;
}

// TODO: we can push greedy into here
global.ajv_create = function(key, meta_schema_version, strict, schema,
                             filename, dependencies, reference) {
    var ret = ajv_create_object(meta_schema_version, strict);

    if (dependencies) {
        dependencies.forEach(
            function(x) {
                // Avoid adding a dependency and then adding it again as the
                // main schema. This might occur if we have recusive references.
                if (x.id !== filename) {
                    ret.addSchema(drop_id(x.value), x.id)
                }
            });
    }

    if (reference === null) {
        ret = ret.addSchema(drop_id(schema), filename).getSchema(filename);
    } else {
        ret = ret.addSchema(drop_id(schema), filename).getSchema(reference);
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

global.ajv_call = function(key, value, errors, query) {
    var validator = validators["ajv"][key];
    var success = validator(jsonpath_eval(value, query));
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
        } else if (typeof(x) === "object" && x !== null) {
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

// It might be nice to do this with jsonpath, but that does not seem
// to work well with browserify.  For now, we're going to accept
// 'query' as a string corresponding to a single element
global.jsonpath_eval = function(data, query) {
    if (query === null) {
        return(data);
    }
    if (data === null || Array.isArray(data) || typeof(data) !== "object") {
        throw new Error("Query only supported with object json");
    } else if (!(query in data)) {
        throw new Error("Query did not match any element in the data");
    }
    return data[query];
}
