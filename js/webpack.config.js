const webpack = require('webpack');
const path = require("path");
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    mode: "none",
    target: ["web", "es5"],
    entry: "./in.js",
    output: {
        path: path.resolve(__dirname),
        filename: "bundle.js"
    },
    module: {
        rules: [
            {
                test: /\.m?js$/,
                "exclude": [
                    /node_modules[\/]core-js/,
                    /node_modules[\/]webpack[\/]buildin/
                ],
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: [['@babel/preset-env', {
                            // Babel 8 compiles for browserslist "defaults" when
                            // no target is given; the bundle must stay ES5 for
                            // the legacy V8 engine, which Babel 7 did by default.
                            targets: {ie: '11'}
                        }]]
                    }
                }
            }
        ]
    },
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin({
                extractComments: false,
                terserOptions: {
                    format: {
                        comments: false,
                    }
                }
            })
        ]
    },
    plugins: [
        new webpack.ProvidePlugin({
            process: 'process/browser',
        })
    ],
    resolve: {
        fallback: {
            util: require.resolve("util/")
        }
    }
}
