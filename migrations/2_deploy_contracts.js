const colors = require('colors')

const ETH = 1000000000000000000

const printToken = () => {
    console.log(colors.green("========================================================================"))
    console.log(colors.green("                              ┌┬┐┌─┐┬┌─┌─┐┌┐┌                           "))
    console.log(colors.green("                               │ │ │├┴┐├┤ │││                           "))
    console.log(colors.green("                               ┴ └─┘┴ ┴└─┘┘└┘                           "))
    console.log(colors.green("========================================================================"))
}

const printCrowdsale = () => {
    console.log(colors.green("========================================================================"))
    console.log(colors.green("                      ┌─┐┬─┐┌─┐┬ ┬┌┬┐┌─┐┌─┐┬  ┌─┐                       "))
    console.log(colors.green("                      │  ├┬┘│ ││││ ││└─┐├─┤│  ├┤                        "))
    console.log(colors.green("                      └─┘┴└─└─┘└┴┘─┴┘└─┘┴ ┴┴─┘└─┘                       "))
    console.log(colors.green("========================================================================"))
}

const printBorder = () => {
    console.log(colors.grey("////////////////////////////////////////////////////////////////////////"))
    console.log(colors.grey("////////////////////////////////////////////////////////////////////////"))
}

const Whitelist = artifacts.require('Whitelist')
const SaleManager = artifacts.require('SaleManager')
const MintableToken = artifacts.require('MintableToken')
const PresaleSecond = artifacts.require('PresaleSecond')

const deployTest = async (deployer, accounts) => {
    const owner = accounts[0]
    const buyers = accounts.slice(1, 6)
    const fraud = accounts[6]

    const maxcap = 25
    const exceed = 15
    const minimum = 2
    const rate = 11500

    await deployer.deploy(Whitelist, { from: owner })
    await deployer.deploy(MintableToken, { from: owner })
    await deployer.deploy(PresaleSecond,
        maxcap*ETH,
        exceed*ETH,
        minimum*ETH,
        rate,

        owner,
        owner,

        Whitelist.address,
        MintableToken.address,
        { from: owner },
    )
    await deployer.deploy(
        SaleManager,
        PresaleSecond.address,
        { from: owner },
    )

    const token = await MintableToken.deployed()
    const whitelist = await Whitelist.deployed()
    const saleManager = await SaleManager.deployed()
    const presaleSecond = await PresaleSecond.deployed()

    await whitelist.addAddressesToWhitelist(
        buyers,
        { from: owner }
    )

    await presaleSecond.setDistributor(SaleManager.address)

    await token.mint(
        PresaleSecond.address,
        maxcap*ETH * rate,
        { from: owner }
    )

    console.log(colors.red("============================ !!Check List!! ============================"))
    console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()))
    console.log(colors.yellow("=> Token address            ") + ": " + colors.cyan(Token.address))
    console.log(colors.yellow("=> Whitelist address        ") + ": " + colors.cyan(Whitelist.address))
    console.log(colors.yellow("=> SaleManager address      ") + ": " + colors.cyan(SaleManager.address))
    console.log(colors.yellow("=> PresaleSecond address    ") + ": " + colors.cyan(PresaleSecond.address))
    console.log(colors.red("========================================================================"))
}

module.exports = async (deployer, network, accounts) => {
    console.clear()
    printBorder()

    switch (network) {
        case "development":
        case "ropsten":
        case "rinkeby":
            await deployTest(deployer, accounts)
        case "mainnet":
            console.log(colors.red("Warning : Deploy on Mainnet"))
            break
        default:

    }
}
