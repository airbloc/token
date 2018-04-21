const colors = require('colors');

const ETH = 1000000000000000000;
const ABL = artifacts.require('ABL');
const ABLG = artifacts.require('ABLG');


const PresaleFirst = artifacts.require('PresaleFirst');

const { duration } = require('../test/helpers/increaseTime');

async function deployToken(owner, deployer) {
    let afterBalance = 0;

    console.log(colors.green("========================================================================"));
    console.log(colors.green("                              ┌┬┐┌─┐┬┌─┌─┐┌┐┌                           "));
    console.log(colors.green("                               │ │ │├┴┐├┤ │││                           "));
    console.log(colors.green("                               ┴ └─┘┴ ┴└─┘┘└┘                           "));
    console.log(colors.green("========================================================================"));

    // deploy ABL token
    deployer.deploy(ABL,
        '0x032d08350f4f44ec654a1cd857bcbd359daf1fa9', // Distribute
        '0xdcfabaf14442ee98c9cca6f5e40bb97e05e77319', // Developer
    ).then(() => {
        // deploy ABLG token
        deployer.deploy(
            ABLG
        ).then(() => {
            // print checklist
            console.log(colors.red("============================ !!Check List!! ============================"));
            console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()));
            console.log(colors.yellow("=> Address of ABL           ") + ": " + colors.cyan(ABL.address.toString()));
            console.log(colors.yellow("=> Address of ABLG          ") + ": " + colors.cyan(ABLG.address.toString()));
            console.log(colors.red("========================================================================"));
            console.log(colors.grey("////////////////////////////////////////////////////////////////////////"));
            console.log(colors.grey("////////////////////////////////////////////////////////////////////////"));

            deployCrowdsale(owner, deployer);
        });
    });
}

async function deployCrowdsale(owner, deployer) {
    const startTime = Date.now();
    const endTime = startTime + duration.years(1);

    const maxEth = 100;
    const exdEth = 30;
    const minEth = 0.5;

    const rate = 11500;

    console.log(colors.green("========================================================================"));
    console.log(colors.green("                      ┌─┐┬─┐┌─┐┬ ┬┌┬┐┌─┐┌─┐┬  ┌─┐                       "));
    console.log(colors.green("                      │  ├┬┘│ ││││ ││└─┐├─┤│  ├┤                        "));
    console.log(colors.green("                      └─┘┴└─└─┘└┴┘─┴┘└─┘┴ ┴┴─┘└─┘                       "));
    console.log(colors.green("========================================================================"));

    // deploy ABLG exchanger
    deployer.deploy(PresaleFirst,
        startTime, endTime, // Time limit
        maxEth*ETH, exdEth*ETH, minEth*ETH, // Fund limit
        owner, // Fund wallet
        ABL.address, // Token address
        rate,    // Exchange rate [ETH : ABL]
    ).then(() => {
        // print checklist
        console.log(colors.red("============================ !!Check List!! ============================"));
        console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()));
        console.log(colors.yellow("=> Address of PresaleFirst  ") + ": " + colors.cyan(PresaleFirst.address.toString()));
        console.log(colors.red("========================================================================"));
    });
}

module.exports = async (deployer, network, accounts) => {
    if(network == "ropsten" || network == "rinkeby") {
        deployToken(accounts[0], deployer);
    }
}
