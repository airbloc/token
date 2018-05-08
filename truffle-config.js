require('babel-register');
require('babel-polyfill');

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gas: 250000,
        }
    },
    mocha: {
        reporter: 'eth-gas-reporter',
        reporterOptions: {
            currency: 'KRW'
        }
    },
    solcjs: {
        optimizer: {
            "enabled": true,
            "runs": 200
        }
    }
};
