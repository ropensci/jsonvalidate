const webpack = require('webpack');
const path = require("path");
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
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
                    /node_modules[\/]webpack[\/]buildin/,
                ],
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
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
                    },
                },
            }),
        ],
    },
    plugins: [
        // fix "process is not defined" error:
        // (do "npm install process" before running the build)
        new webpack.ProvidePlugin({
            process: 'process/browser',
        }),
    ],
    resolve: {
        fallback: {
            util: require.resolve("util/")
        }
    }
}
