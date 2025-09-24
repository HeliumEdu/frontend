const merge = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
        devtool: 'inline-source-map',
        devServer: {
            port: 3000,
            historyApiFallback: {
                rewrites: [
                    {from: /^\/$/, to: '/index.html'},
                    {from: /^\/tour/, to: '/tour.html'},
                    {from: /^\/register/, to: '/register.html'},
                    {from: /^\/verify/, to: '/verify.html'},
                    {from: /^\/login/, to: '/login.html'},
                    {from: /^\/forgot/, to: '/forgot.html'},
                    {from: /^\/logout/, to: '/logout.html'},
                    {from: /^\/support/, to: '/support.html'},
                    {from: /^\/docs/, to: '/docs.html'},
                    {from: /^\/status/, to: '/status.html'},
                    {from: /^\/admin/, to: '/admin.html'},
                    {from: /^\/about/, to: '/about.html'},
                    {from: /^\/contact/, to: '/contact.html'},
                    {from: /^\/press/, to: '/press.html'},
                    {from: /^\/privacy/, to: '/privacy.html'},
                    {from: /^\/terms/, to: '/terms.html'},
                    {from: /^\/settings/, to: '/settings.html'},
                    {from: /^\/planner$/, to: '/planner.html'},
                    {from: /^\/planner\/calendar/, to: '/planner/calendar.html'},
                    {from: /^\/planner\/classes/, to: '/planner/classes.html'},
                    {from: /^\/planner\/materials/, to: '/planner/materials.html'},
                    {from: /^\/planner\/grades/, to: '/planner/grades.html'},
                    {from: /^\/health/, to: '/health.json'},
                    {from: /./, to: '/404.html'}
                ]
            }
        }
    }
);
