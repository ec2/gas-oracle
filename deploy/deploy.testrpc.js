const HttpProvider = require('ethjs-provider-http');

module.exports = (options) => ({ // eslint-disable-line
  entry: [
    './environments.json',
    '../contracts',
  ],
  output: {
    path: './',
    filename: 'environments.json',
    safe: true,
  },
  module: {
    environment: {
      name: 'testrpc',
      provider: new HttpProvider('http://localhost:8545'),
      defaultTxObject: {
        from: 1,
        gas: 3000001,
      },
    },
    preLoaders: [
      { test: /\.(json)$/, loader: 'ethdeploy-environment-loader' },
    ],
    loaders: [
      { test: /\.(sol)$/, loader: 'ethdeploy-solc-loader', optimize: 1, filterWarnings: true },
    ],
		deployment: (deploy, contracts, done) => {
			deploy(contracts['../contracts/Database.sol:Database'], { from: 0}) .then((contractInstance) => {
				deploy(contracts['../contracts/GasHole.sol:GasHole'], contractInstance.address, { from: 0 }).then(() => {
					done();
				});
			});
    },
  },
  plugins: [
    new options.plugins.JSONFilter(),
    new options.plugins.JSONMinifier(),
  ],
});
