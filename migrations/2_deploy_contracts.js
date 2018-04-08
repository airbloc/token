var abl = artifacts.require("./ABL.sol");

module.exports = function(deployer) {
    const PVT = web3.eth.accounts[0];
    const PRE = web3.eth.accounts[1];
    const PUB = web3.eth.accounts[2];
    const DEV = web3.eth.accounts[3];

    deployer.deploy(abl, PVT, PRE, PUB, DEV);
}
