require('babel-register')
require('babel-polyfill')

console.clear()

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*"
        }
    },
    solcjs: {
        optimizer: {
            "enabled": true,
            "runs": 200
        }
    }
}
