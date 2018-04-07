var AirblocToken = artifacts.require("./AirblocToken.sol");

module.exports = function(deployer) {
    const PVT = web3.eth.accounts[26];
    const PRE = web3.eth.accounts[27];
    const PUB = web3.eth.accounts[28];
    const DEV = web3.eth.accounts[29];

    deployer.deploy(AirblocToken, PVT, PRE, PUB, DEV);
    
}
