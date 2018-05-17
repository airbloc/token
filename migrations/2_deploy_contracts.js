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
const MintableToken = artifacts.require('MintableToken')
const PresaleSecond = artifacts.require('PresaleSecond')

module.exports = async (deployer, network, accounts) => {
    const owner = accounts[0]

    // if(network == "development") {
    //     // whitelist
    //     await deployer.deploy(Whitelist)
    //     await deployer.deploy(MintableToken)
    //
    //     // token sale
    //     const maxcap = 20
    //     const exceed = 10
    //     const minimum = 2
    //     const rate = 11500
    //
    //     const startTime = Date.now() / 1000
    //     const endTime = startTime + 86400
    //
    //     await deployer.deploy(PresaleSecond,
    //         maxcap*ETH,
    //         exceed*ETH,
    //         minimum*ETH,
    //         rate,
    //
    //         owner,
    //         owner,
    //
    //         Whitelist.address,
    //         MintableToken.address
    //     )
    //
    //     console.log(colors.red("============================ !!Check List!! ============================"))
    //     console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()))
    //     console.log(colors.yellow("=> Whitelist address        ") + ": " + colors.cyan(Whitelist.address))
    //     console.log(colors.yellow("=> PresaleSecond address    ") + ": " + colors.cyan(PresaleSecond.address))
    //     console.log(colors.red("========================================================================"))
    // }
}
