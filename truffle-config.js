require('babel-register');
require('babel-polyfill');

const HDWalletProvider = require("truffle-hdwallet-provider");

const infura_apikey = "XXXXXXXXXXXXXXXXXXXX";
const mnemonic = "airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge";

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gas: 4300000
        },
        main: {
            network_id: 1,
            provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infura_apikey),
            gas: 3700000
        },
        ropsten: {
            network_id: 3,
            provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infura_apikey),
            gas: 3700000
        },
        rinkeby: {
            network_id: 4,
            provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey),
            gas: 3000000
        }
    }
};
