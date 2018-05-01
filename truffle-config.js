require('babel-register');
require('babel-polyfill');

const newProvider = require('./config.local.test.js');
const main = require('./config.local.deploy.js');

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gas: 250000,
        },
        main: {
            network_id: 1,
            provider: main()
        },
        ropsten: {
            network_id: 3,
            provider: newProvider('ropsten'),
            gas: 3000000,
        },
        rinkeby: {
            network_id: 4,
            provider: newProvider('rinkeby'),
            gas: 500000,
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
