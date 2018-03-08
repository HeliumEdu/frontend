const path = require('path');
const _ = require('lodash');
const CopyWebpackPlugin = require('copy-webpack-plugin')
const NunjucksWebpackPlugin = require("nunjucks-webpack-plugin");

const publicPath = "";
const projectName = "Helium Student Planner";
const projectTagline = "Lightening Your Course Load";
const projectVersion = require("./package.json").version;

const min_suffix = process.env.NODE_ENV === 'production' ? '.min' : '';

const defaultContext = {
    'PUBLIC_PATH': publicPath,
    'PROJECT_NAME': projectName,
    'PROJECT_TAGLINE': projectTagline,
    'PROJECT_EMAIL': "contact@heliumedu.com",
    'PROJECT_VERSION': projectVersion,
    'COPYRIGHT_YEAR': new Date().getFullYear(),
    'base_javascript': [
        path.join('assets', 'js', 'vendors', `moment${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `moment-timezone${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `jquery.ui.touch-punch${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `chosen.jquery${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `spin${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `jquery.spin${min_suffix}.js`),
        path.join('assets', 'js', `base${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `ace-elements${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `ace${min_suffix}.js`),
        path.join('assets', 'js', `api${min_suffix}.js`)
    ],
    'base_header_javascript': [
        path.join('assets', 'js', 'vendors', `ace-extra${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `js.cookie${min_suffix}.js`)
    ],
    'base_ie9_javascript': [
        path.join('assets', 'js', 'vendors', `html5shiv${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `respond${min_suffix}.js`)
    ],
    'base_stylesheet': [
        path.join('assets', 'css', 'vendors', `jquery-ui.full${min_suffix}.css`),
        path.join('assets', 'css', 'vendors', `chosen${min_suffix}.css`),
        path.join('assets', 'css', 'vendors', `font-awesome${min_suffix}.css`),
        path.join('assets', 'css', 'vendors', `ace-fonts${min_suffix}.css`),
        path.join('assets', 'css', 'vendors', `ace${min_suffix}.css`),
        path.join('assets', 'css', `base${min_suffix}.css`)
    ],
    'base_ie8_stylesheet': [
        path.join('assets', 'css', 'vendors', `ace-ie${min_suffix}.css`)
    ],
};

module.exports = {
    context: path.resolve(__dirname, "src"),
    entry: './assets/js/base.js',
    output: {
        filename: path.join('js', `[name].${projectVersion}.bundle.js`),
        path: path.resolve(__dirname, 'build'),
        publicPath: publicPath
    },
    plugins: [
        // Image assets
        new CopyWebpackPlugin([
            {
                from: '**/*.+(png|jpg|jpeg|gif|svg|ico)'
            }
        ]),
        // Font assets
        new CopyWebpackPlugin([
            {
                from: '**/*.+(woff|otf|eot|tff)'
            }
        ]),
        // Script and style assets
        new CopyWebpackPlugin([
            {
                from: '**/*.+(css|js)'
            }
        ]),
        // Static page assets
        new CopyWebpackPlugin([
            {
                from: '**/*.+(txt|html)'
            }
        ]),
        // Compile Nunjucks templates into HTML static page assets
        new NunjucksWebpackPlugin({
            templates: [
                {
                    from: path.join("src", "templates", "index.njk"),
                    to: "index.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "login.njk"),
                    to: "login.html",
                    context: _.extend({}, defaultContext, {
                        "page_javascript": [path.join('assets', 'js', `login${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "logout.njk"),
                    to: "logout.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `logout${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "support.njk"),
                    to: "support.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `support${min_suffix}.js`)]
                    })
                },
            ]
        })
    ]
};
