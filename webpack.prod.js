const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin')

module.exports = merge(common, {
    plugins: [
        new CleanWebpackPlugin(['build']),
        new UglifyJSPlugin()
    ]
});
