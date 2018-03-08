const merge = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
    devtool: 'inline-source-map',
    devServer: {
        port: 3000,
        historyApiFallback: {
            rewrites: [
                { from: /^\/$/, to: '/index.html' },
                { from: /^\/register/, to: '/register.html' },
                { from: /^\/login/, to: '/login.html' },
                { from: /^\/forgot/, to: '/forgot.html' },
                { from: /^\/logout/, to: '/logout.html' },
                { from: /^\/support/, to: '/support.html' },
                { from: /./, to: '/404.html' }
            ]
        }
    }
});
