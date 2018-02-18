const polyfill = require('babel-polyfill');
const path = require('path');

module.exports = {
  entry: [
    'babel-polyfill',
    path.join(__dirname, 'src/index.js')
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  devtool: '#eval-source-map',
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        include: path.join(__dirname, 'src'),
        use: [
          {
            loader: 'babel-loader',
            options: {
              babelrc: false,
              presets: [
                ['env', { modules: false }],
                'react',
                'stage-3'
              ],
            }
          }
        ]
      },
      {
        test: /\.(css)$/,
        loader: ['style-loader', 'css-loader']
      }
    ]
  },
};
