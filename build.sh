#!/bin/sh
echo "global.validator = require('is-my-json-valid');" > in.js
browserify in.js -o inst/is-my-json-valid.js
rm in.js
