global.Ajv = require('ajv');
global.AjvSchema4 = require('ajv/lib/refs/json-schema-draft-04.json');
global.AjvSchema6 = require('ajv/lib/refs/json-schema-draft-06.json');

global.ajv = new Ajv({allErrors: true, verbose: true})
    .addMetaSchema(AjvSchema6);

global.ajv_04 = new Ajv({meta: false, schemaId: 'id', allErrors: true, verbose: true})
    .addMetaSchema(AjvSchema4)
    .removeKeyword('propertyNames')
    .removeKeyword('contains')
    .removeKeyword('const')
    .removeKeyword('if')
    .removeKeyword('then')
    .removeKeyword('else');

global.get_meta_schema = function(schema) {
  return schema.$schema;
};

global.imjv = require('is-my-json-valid');
