const path = require('path');
const _ = require('lodash');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin')
const NunjucksWebpackPlugin = require("nunjucks-webpack-plugin");

const publicPath = "";
const projectName = "Helium Student Planner";
const projectTagline = "Lightening Your Course Load";
const projectVersion = require("./package.json").version;

const defaultContext = {
    PUBLIC_PATH: publicPath,
    PROJECT_NAME: projectName,
    PROJECT_TAGLINE: projectTagline,
    PROJECT_EMAIL: "contact@heliumedu.com",
    PROJECT_VERSION: projectVersion,
    COPYRIGHT_YEAR: new Date().getFullYear()
};

module.exports = {
    context: path.resolve(__dirname, "src"),
    entry: {
        'base': './assets/js/base.js',
        'api': './assets/js/api.js'
    },
    output: {
        filename: path.join('js', `[name].${projectVersion}.bundle.js`),
        path: path.resolve(__dirname, 'dist'),
        publicPath: publicPath
    },
    plugins: [
        new CleanWebpackPlugin(['dist']),
        new CopyWebpackPlugin([
            {
                from: '**/*.+(png|jpg|jpeg|gif|svg)'
            }
        ]),
        new CopyWebpackPlugin([
            {
                from: '**/*.+(woff|otf|eot|tff)'
            }
        ]),
        new NunjucksWebpackPlugin({
            templates: [{
                from: "src/templates/index.html",
                to: "index.html",
                context: _.extend(defaultContext, {
                    'javascript': [
                        path.join('js', `base.${projectVersion}.bundle.js`)
                    ]
                })
            }]
        })
    ]
};