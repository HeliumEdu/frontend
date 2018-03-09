const path = require('path');
const _ = require('lodash');
const CopyWebpackPlugin = require('copy-webpack-plugin');
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
        path.join('assets', 'js', 'vendors', `js.cookie${min_suffix}.js`),
        path.join('assets', 'js', 'vendors', `url${min_suffix}.js`)
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
    ]
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
                    from: path.join("src", "templates", "404.njk"),
                    to: "404.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "500.njk"),
                    to: "500.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "503.njk"),
                    to: "503.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "index.njk"),
                    to: "index.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "register.njk"),
                    to: "register.html",
                    context: _.extend({}, defaultContext, {
                        "page_javascript": [path.join('assets', 'js', `register${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "base.njk"),
                    to: "verify.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `verify${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "login.njk"),
                    to: "login.html",
                    context: _.extend({}, defaultContext, {
                        "page_javascript": [path.join('assets', 'js', `login${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "forgot.njk"),
                    to: "forgot.html",
                    context: _.extend({}, defaultContext, {
                        "page_javascript": [path.join('assets', 'js', `forgot${min_suffix}.js`)]
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
                    from: path.join("src", "templates", "base.njk"),
                    to: "support.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `support${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "about.njk"),
                    to: "about.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "contact.njk"),
                    to: "contact.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "press.njk"),
                    to: "press.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "privacy.njk"),
                    to: "privacy.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "terms.njk"),
                    to: "terms.html",
                    context: defaultContext
                },
                {
                    from: path.join("src", "templates", "settings.njk"),
                    to: "settings.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `authenticated${min_suffix}.js`)],
                        "page_stylesheet_pre": [
                            path.join('assets', 'css', 'vendors', `bootstrap-editable${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery-simplecolorpicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery-simplecolorpicker-glyphicons${min_suffix}.css`)
                        ],
                        "page_stylesheet": [path.join('assets', 'css', `settings${min_suffix}.css`)],
                        "page_javascript": [
                            path.join('assets', 'js', 'vendors', `bootstrap-editable${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.simplecolorpicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootbox${min_suffix}.js`),
                            path.join('assets', 'js', `settings${min_suffix}.js`)
                        ]
                    })
                },
                {
                    from: path.join("src", "templates", "base.njk"),
                    to: "planner/index.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `planner${min_suffix}.js`)]
                    })
                },
                {
                    from: path.join("src", "templates", "calendar.njk"),
                    to: "planner/calendar.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `authenticated${min_suffix}.js`)],
                        "page_stylesheet_pre": [
                            path.join('assets', 'css', 'vendors', `bootstrap-editable${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `fullcalendar${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `datepicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `bootstrap-timepicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery.simplecolorpicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery.simplecolorpicker-glyphicons${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `dropzone${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery.qtip${min_suffix}.css`)
                        ],
                        "page_stylesheet_print": [path.join('assets', 'css', 'vendors', `fullcalendar.print${min_suffix}.css`)],
                        "page_stylesheet": [path.join('assets', 'css', `calendar${min_suffix}.css`)],
                        "page_javascript": [
                            path.join('assets', 'js', 'vendors', `bootstrap-datepicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-timepicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-editable${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootbox${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables.bootstrap${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `fullcalendar${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `dropzone${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.qtip${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.hotkeys${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-wysiwyg${min_suffix}.js`),
                            path.join('assets', 'js', `calendar${min_suffix}.js`),
                            path.join('assets', 'js', `calendar-triggers${min_suffix}.js`)
                        ]
                    })
                },
                {
                    from: path.join("src", "templates", "classes.njk"),
                    to: "planner/classes.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `authenticated${min_suffix}.js`)],
                        "page_stylesheet_pre": [
                            path.join('assets', 'css', 'vendors', `bootstrap-editable${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `typeahead.js-bootstrap${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `datepicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `bootstrap-timepicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery.simplecolorpicker${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `jquery.simplecolorpicker-glyphicons${min_suffix}.css`),
                            path.join('assets', 'css', 'vendors', `dropzone${min_suffix}.css`)
                        ],
                        "page_stylesheet": [path.join('assets', 'css', `classes${min_suffix}.css`)],
                        "page_javascript": [
                            path.join('assets', 'js', 'vendors', `bootstrap-datepicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-timepicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-editable${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `typeahead${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `typeaheadjs${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootbox${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables.bootstrap${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.simplecolorpicker${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `dropzone${min_suffix}.js`),
                            path.join('assets', 'js', `classes${min_suffix}.js`),
                            path.join('assets', 'js', `classes-triggers${min_suffix}.js`)
                        ]
                    })
                },
                {
                    from: path.join("src", "templates", "materials.njk"),
                    to: "planner/materials.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `authenticated${min_suffix}.js`)],
                        "page_stylesheet_pre": [path.join('assets', 'css', 'vendors', `bootstrap-editable${min_suffix}.css`)],
                        "page_stylesheet": [path.join('assets', 'css', `materials${min_suffix}.css`)],
                        "page_javascript": [
                            path.join('assets', 'js', 'vendors', `bootstrap-editable${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootbox${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.dataTables.bootstrap${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.hotkeys${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `bootstrap-wysiwyg${min_suffix}.js`),
                            path.join('assets', 'js', `materials${min_suffix}.js`),
                            path.join('assets', 'js', `materials-triggers${min_suffix}.js`)
                        ]
                    })
                },
                {
                    from: path.join("src", "templates", "grades.njk"),
                    to: "planner/grades.html",
                    context: _.extend({}, defaultContext, {
                        "redirect_javascript": [path.join('assets', 'js', `authenticated${min_suffix}.js`)],
                        "page_stylesheet_pre": [path.join('assets', 'css', `grades${min_suffix}.css`)],
                        "page_javascript": [
                            path.join('assets', 'js', 'vendors', `bootbox${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.easy-pie-chart${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.flot${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.flot.pie${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.flot.resize${min_suffix}.js`),
                            path.join('assets', 'js', 'vendors', `jquery.flot.time${min_suffix}.js`),
                            path.join('assets', 'js', `grades${min_suffix}.js`)
                        ]
                    })
                }
            ]
        })
    ]
};
