global.Ajv = require('ajv');
global.AjvSchema4 = require('ajv/lib/refs/json-schema-draft-04.json');
global.AjvSchema6 = require('ajv/lib/refs/json-schema-draft-06.json');

global.AjvGenerator =
    new Ajv({allErrors: true, schemaId: 'auto', verbose: true});
global.AjvGenerator.addMetaSchema(AjvSchema4);
global.AjvGenerator.addMetaSchema(AjvSchema6);

global.imjv = require('is-my-json-valid');
