const colors = require('colors');

const ETH = 1000000000000000000;
const ABL = artifacts.require('ABL');
const ABLG = artifacts.require('ABLG');


const PresaleFirst = artifacts.require('PresaleFirst');

const { duration } = require('../test/helpers/increaseTime');

function printToken() {
    console.log(colors.green("========================================================================"));
    console.log(colors.green("                              ┌┬┐┌─┐┬┌─┌─┐┌┐┌                           "));
    console.log(colors.green("                               │ │ │├┴┐├┤ │││                           "));
    console.log(colors.green("                               ┴ └─┘┴ ┴└─┘┘└┘                           "));
    console.log(colors.green("========================================================================"));
}

function printCrowdsale() {
    console.log(colors.green("========================================================================"));
    console.log(colors.green("                      ┌─┐┬─┐┌─┐┬ ┬┌┬┐┌─┐┌─┐┬  ┌─┐                       "));
    console.log(colors.green("                      │  ├┬┘│ ││││ ││└─┐├─┤│  ├┤                        "));
    console.log(colors.green("                      └─┘┴└─└─┘└┴┘─┴┘└─┘┴ ┴┴─┘└─┘                       "));
    console.log(colors.green("========================================================================"));
}

function printBorder() {
    console.log(colors.grey("////////////////////////////////////////////////////////////////////////"));
    console.log(colors.grey("////////////////////////////////////////////////////////////////////////"));
}

module.exports = async (deployer, network, accounts) => {
    const owner = accounts[0];

    const startNumber = 5490000;
    const endNumber = 5532000;

    if(network == "ropsten" || network == "rinkeby" || network == "development") {
        const startNumber = 3081200;
        const endNumber = startNumber + 30;

        printToken();

        // deploy ABL token
        await deployer.deploy(ABL,
            '0x82ccd4b49566fa0444b740c460c9d456476e0e8b', // Distribute - Frostornge: 1
            '0x1307151b20eb73156327178aae256e85e3bfb971', // Developer  - Frostornge: 2
        );

        printBorder();

        printCrowdsale();

        await deployer.deploy(PresaleFirst,
            startNumber,
            endNumber, // Time limit
            owner, // Fund wallet
            ABL.address, // Token address
        )

        printBorder();

        const abl = await ABL.deployed();
        const pfi = await PresaleFirst.deployed();

        console.log("  Create Transactions...")

        await abl.addOwner(PresaleFirst.address);
        await abl.addOwner('0x82ccd4b49566fa0444b740c460c9d456476e0e8b');

        await pfi.addAddressesToWhitelist([
            '0x605d1f5241a09cbe1143ee9740c466f454554c6d',
            '0x82ccd4b49566fa0444b740c460c9d456476e0e8b',
            '0x1307151b20eb73156327178aae256e85e3bfb971',
        ]);

        printBorder();

        console.log(colors.red("============================ !!Check List!! ============================"));
        console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()));
        console.log(colors.yellow("=> Address of ABL           ") + ": " + colors.cyan(ABL.address.toString()));
        console.log(colors.yellow("=> Address of PresaleFirst  ") + ": " + colors.cyan(PresaleFirst.address.toString()));
        console.log(colors.red("========================================================================"));
    } else {
        const mainDistWallet = '0x31d2d0f8180c3300e4f19271aF5403225Fe4cF24';
        const mainDevWallet = '0x857fA0E10F70593a7D2505361a03505E9Be1F935';

        console.log('WARNING: Deploying To MAINNET.')
        // printToken();

        // deploy ABL token
        // await deployer.deploy(ABL, mainDistWallet, mainDevWallet)
        //
        // printBorder();
        printCrowdsale();

        await deployer.deploy(PresaleFirst,
            startNumber,
            endNumber, // Time limit
            owner, // Fund wallet
            '0xf8b358b3397a8ea5464f8cc753645d42e14b79ea'/*ABL.address*/, // Token address
        )

        printBorder();

        const abl = ABL.at('0xf8b358b3397a8ea5464f8cc753645d42e14b79ea');
        const pfi = await PresaleFirst.deployed();

        console.log("  Create Transactions...")

        await abl.addOwner(PresaleFirst.address);
        await abl.addOwner(mainDistWallet);
        await abl.addOwner(mainDevWallet);

        printBorder();

        console.log(colors.red("============================ !!Check List!! ============================"));
        console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()));
        console.log(colors.yellow("=> Address of PresaleFirst  ") + ": " + colors.cyan(PresaleFirst.address.toString()));
        console.log(colors.red("========================================================================"));
    }
}
