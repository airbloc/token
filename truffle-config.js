require('babel-register')
require('babel-polyfill')

const newProvider = require('./config.local.provider.js')

console.clear()

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*"
        },
        mainnet: {
            provider: newProvider('mainnet'),
            network_id: 1,
            gas: 2800000,
            gasPrice: 18000000000
        },
        ropsten: {
            provider: newProvider('ropsten'),
            network_id: 3,
            gas: 3000000
        },
        rinkeby: {
            provider: newProvider('rinkeby'),
            network_id: 4,
            gas: 3000000
        }
    },
    solcjs: {
        optimizer: {
            "enabled": true,
            "runs": 200
        }
    }
}
