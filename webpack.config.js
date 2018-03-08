const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const NunjucksWebpackPlugin = require("nunjucks-webpack-plugin");

const publicPath = "";
const projectName = "Helium Student Planner";
const projectTagline = "Lightening Your Course Load";

const defaultContext = {
    PUBLIC_PATH: publicPath,
    PROJECT_NAME: projectName,
    PROJECT_TAGLINE: projectTagline,
    PROJECT_EMAIL: "contact@heliumedu.com",
    PROJECT_VERSION: require("./package.json").version,
    COPYRIGHT_YEAR: new Date().getFullYear()
};

module.exports = {
    context: path.resolve(__dirname, "src"),
    entry: {
        'base': './assets/js/base.js',
        'api': './assets/js/api.js'
    },
    output: {
        filename: '[name].bundle.[chunkhash].js',
        path: path.resolve(__dirname, 'dist'),
        publicPath: publicPath
    },
    plugins: [
        new CleanWebpackPlugin(['dist']),
        new NunjucksWebpackPlugin({
            templates: [{
                from: "src/templates/index.html",
                to: "index.html",
                context: defaultContext
            }]
        })
    ]
};