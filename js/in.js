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
global.ajv_create = function(key, meta_schema_version, schema, reference) {
    var ret = ajv_create_object(meta_schema_version);
    if (reference === null) {
        ret = ret.compile(schema);
    } else {
        ret = ret.addSchema(schema).getSchema(reference);
    }
    validators["ajv"][key] = ret;
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

global.cleanup = function(type, name) {
    delete validators[type][name];
}

global.get_meta_schema_version = function(schema) {
  return schema.$schema;
};
