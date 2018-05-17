const colors = require('colors')

const ETH = 1000000000000000000

const ether = (value) => {
    return value * ETH
}

require('chai')
    .use(require('chai-as-promised'))
    .should()

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

// 0.5 eth, no exceed
const testCase1 = async (presaleSecond, buyers) => {
    for (let buyer of buyers)
        await presaleSecond.sendTransaction({ from: buyer, value: ether(0.1) }).should.be.fulfilled
}

// 0.8 eth, exceed indivisual cap
const testCase2 = async (presaleSecond, buyers) => {
    for (let buyer of buyers)
        await presaleSecond.sendTransaction({ from: buyer, value: ether(0.1) }).should.be.fulfilled
    await presaleSecond.sendTransaction({ from: buyers[0], value: ether(1) }).should.be.fulfilled
}

// 0.5 + 0.3 + 0.2 eth, exceed indivisual cap and sale hardcap
const testCase3 = async (presaleSecond, buyers) => {
    for (let buyer of buyers)
        await presaleSecond.sendTransaction({ from: buyer, value: ether(0.1) }).should.be.fulfilled
    await presaleSecond.sendTransaction({ from: buyers[0], value: ether(1) }).should.be.fulfilled
    await presaleSecond.sendTransaction({ from: buyers[1], value: ether(1) }).should.be.fulfilled
}

const deployTest = async (deployer, accounts) => {
    printBorder()
    const owner = accounts[0]
    const buyers = accounts.slice(1, 6)
    const fraud = accounts[6]

    const maxcap = 1
    const exceed = 0.4
    const minimum = 0.1
    const rate = 11500

    await deployer.deploy(Whitelist, { from: owner })
    await deployer.deploy(MintableToken, { from: owner })
    await deployer.deploy(PresaleSecond,
        ether(maxcap),
        ether(exceed),
        ether(minimum),
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

    printBorder()
    process.stdout.write("Get Instances")
    const token = await MintableToken.deployed()
    const whitelist = await Whitelist.deployed()
    const saleManager = await SaleManager.deployed()
    const presaleSecond = await PresaleSecond.deployed()
    console.log("...ok")

    console.log("Initialize")
    await whitelist.addAddressesToWhitelist(buyers, { from: owner })
    await presaleSecond.setDistributor(SaleManager.address, { from: owner })
    await token.mint(PresaleSecond.address, maxcap*ETH * rate, { from: owner })

    /////////////////////////////////////////////
    console.log("Fraud")
    console.log(":settings")
    await presaleSecond.setWhitelist(Whitelist.address, { from: fraud }).should.be.rejected
    await presaleSecond.setDistributor(SaleManager.address, { from: fraud }).should.be.rejected
    await presaleSecond.setWallet(fraud, { from: fraud }).should.be.rejected

    console.log("-pause")
    await presaleSecond.pause({ from: fraud }).should.be.rejected
    console.log("  log : ", await presaleSecond.paused.call())
    await presaleSecond.resume({ from: fraud }).should.be.rejected
    console.log("  log : ", await presaleSecond.paused.call())

    console.log("-start")
    await presaleSecond.ignite({ from: fraud }).should.be.rejected
    console.log("  log : ", await presaleSecond.ignited.call())
    await presaleSecond.extinguish({ from: fraud }).should.be.rejected
    console.log("  log : ", await presaleSecond.ignited.call())

    console.log(":sale")
    await presaleSecond.sendTransaction({ from: fraud, value: ether(0.1) }).should.be.rejected
    console.log("  log : ", await presaleSecond.weiRaised.call())
    await presaleSecond.sendTransaction({ from: buyers[0], value: ether(0.1) }).should.be.rejected
    console.log("  log : ", await presaleSecond.weiRaised.call())

    /////////////////////////////////////////////
    console.log("Owner")
    console.log(":settings")
    await presaleSecond.setWhitelist(Whitelist.address, { from: owner }).should.be.fulfilled
    await presaleSecond.setDistributor(SaleManager.address, { from: owner }).should.be.fulfilled
    await presaleSecond.setWallet(owner, { from: owner }).should.be.fulfilled

    console.log("-pause")
    await presaleSecond.pause({ from: owner }).should.be.fulfilled
    console.log("  log : ", await presaleSecond.paused.call())
    await presaleSecond.resume({ from: owner }).should.be.fulfilled
    console.log("  log : ", await presaleSecond.paused.call())

    console.log("-start")
    await presaleSecond.ignite({ from: owner }).should.be.fulfilled
    console.log("  log : ", await presaleSecond.ignited.call())
    await presaleSecond.extinguish({ from: owner }).should.be.fulfilled
    console.log("  log : ", await presaleSecond.ignited.call())

    /////////////////////////////////////////////
    console.log("On sale")
    console.log(":collect")
    await presaleSecond.ignite({ from: owner }).should.be.fulfilled
    console.log("  Fraud")
    await presaleSecond.sendTransaction({ from: fraud, value: ether(0.1) }).should.be.rejected
    await presaleSecond.sendTransaction({ from: buyers[0], value: ether(0.05) }).should.be.rejected
    console.log("  log : ", await presaleSecond.weiRaised.call())

    console.log("  Buyers")
    await testCase3(presaleSecond, buyers)
    console.log("  log : ", await presaleSecond.weiRaised.call())
    await presaleSecond.extinguish({ from: owner }).should.be.fulfilled

    /////////////////////////////////////////////
    printBorder()
    console.log(colors.red("============================ !!Check List!! ============================"))
    console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()))
    console.log(colors.yellow("=> Token address            ") + ": " + colors.cyan(MintableToken.address))
    console.log(colors.yellow("=> Whitelist address        ") + ": " + colors.cyan(Whitelist.address))
    console.log(colors.yellow("=> SaleManager address      ") + ": " + colors.cyan(SaleManager.address))
    console.log(colors.yellow("=> PresaleSecond address    ") + ": " + colors.cyan(PresaleSecond.address))
    console.log(colors.red("========================================================================"))
}

module.exports = async (deployer, network, accounts) => {
    console.clear()

    switch (network) {
        case "development":
        case "ropsten":
        case "rinkeby":
            await deployTest(deployer, accounts)
            break
        case "mainnet":
            console.log(colors.red("Warning : Deploy on Mainnet"))
            break
        default:
            console.log(colors.red("WTF?"))
    }
}
