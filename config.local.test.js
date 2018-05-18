const HDWalletProvider = require('truffle-hdwallet-provider')
const mnemonic = 'airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge airbloc frostornge'
const key = 'AiRbLoCfRoStOrNgE'

module.exports = (network) => {
    return new HDWalletProvider(mnemonic, `https://${network}.infura.io/${key}`)
}
