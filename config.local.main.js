const LedgerWalletProvider = require('truffle-ledger-provider')
const ledgerOptions = {
    networkId: 99,
    accountsLength: 99,
    accountsOffset: 99
};
const key = 'AiRbLoCfRoStOrNgE'

module.exports = () => {
    return new LedgerWalletProvider(ledgerOptions, `https://mainnet.infura.io/${key}`)
}
