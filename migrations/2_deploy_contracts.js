const colors = require('colors');

const ETH = 1000000000000000000;

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

    console.log(colors.red("============================ !!Check List!! ============================"));
    console.log(colors.yellow("=> Contract owner           ") + ": " + colors.cyan(owner.toString()));
    console.log(colors.red("========================================================================"));
}
