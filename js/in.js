import "core-js/es/set";
import "core-js/es/map";
import "core-js/features/array/find";
import "core-js/features/array/find-index";
import "core-js/features/array/from";
import "core-js/features/array/includes";
import "core-js/features/object/assign";
import "core-js/features/string/starts-with";
import "core-js/features/string/includes";

global.Ajv = require('ajv');
global.AjvSchema4 = require('ajv-draft-04');
global.AjvSchema6 = require('ajv/dist/refs/json-schema-draft-06.json');
global.AjvSchema2019 = require('ajv/dist/2019')
global.AjvSchema2020 = require('ajv/dist/2020')
global.addFormats = require('ajv-formats');

global.imjv = require('is-my-json-valid');

global.ajv_create_object = function(meta_schema_version, strict) {
    // Need to disable strict mode, otherwise we get warnings
    // about unknown schema entries in draft-04 (e.g., presence of
    // const) and draft-07 (e.g. presence of "reference")
    var opts = {allErrors: true,
                verbose: true,
                unicodeRegExp: false,
                strict: strict,
                code: {es5: true}};
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
    } else if (meta_schema_version === "draft/2019-09") {
        var ret = new AjvSchema2019(opts);
    } else if (meta_schema_version === "draft/2020-12") {
        var ret = new AjvSchema2020(opts);
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
global.ajv_create = function(meta_schema_version, strict, schema,
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

    // Save in the global scope so we can use this later from R
    global.validator = ret;
}

global.drop_id = function(x) {
    delete x.id;
    delete x.$id;
    return x;
}

global.imjv_create = function(meta_schema_version, schema) {
    // https://github.com/mafintosh/is-my-json-valid/issues/160
    if (meta_schema_version != "draft-04") {
        throw new Error("Only draft-04 json schema is supported");
    }
    global.validator = imjv(schema);
}

global.ajv_call = function(value, errors, query) {
    var success = validator(jsonpath_eval(value, query));
    var errors = (!success && errors ? validator.errors : null);
    return {"success": success, "errors": errors, "engine": "ajv"};
}

global.imjv_call = function(value, errors, greedy) {
    var success = validator(value, {"greedy": greedy}, {"verbose": errors});
    var errors = (!success && errors ? validator.errors : null);
    return {"success": success, "errors": errors, "engine": "imjv"};
}

global.get_meta_schema_version = function(schema) {
    return schema.$schema;
};

global.find_reference = function(x) {
    var deps = [];

    var f = function(x) {
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
    };
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


global.typeIsAtomic = function(t) {
    // the const one might be overly generous; it might be that a
    // constant non-atomic type is allowed.
    return t === "string" || t === "number" || t === "boolean" ||
        t == "enum" || t == "const" || t == "integer";
}

global.unboxable = function(x) {
    return Array.isArray(x) && x.length === 1 && typeIsAtomic(typeof(x[0]));
}

global.fixUnboxable = function(x, schema) {
    var f = function(x, s, parent, index) {
        if (Array.isArray(x)) {
            if (typeIsAtomic(s.type) && unboxable(x)) {
                if (parent === null) {
                    x = x[0];
                } else {
                    parent[index] = x[0];
                }
            } else {
                var descend = x.length > 0 &&
                    typeof(x[0]) == "object" &&
                    s.hasOwnProperty("items") &&
                    (s.items.type === "object" || s.items.type == "array");
                if (descend) {
                    for (var i = 0; i < x.length; ++i) {
                        f(x[i], s.items, x, i);
                    }
                }
            }
        } else if (typeof(x) === "object" && x !== null) {
            if (s.type === "object") {
                var keys = Object.keys(s.properties);
                for (var i = 0; i < keys.length; ++i) {
                    var k = keys[i];
                    if (x.hasOwnProperty(k)) {
                        f(x[k], s.properties[k], x, k);
                    }
                }
            }
        }
        return x;
    }

    x = f(x, schema.schema, null);
    return x;
}

global.safeSerialise = function(x) {
    var x = JSON.parse(x);
    return JSON.stringify(fixUnboxable(x, validator));
}
