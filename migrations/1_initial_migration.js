var Migrations = artifacts.require("./util/Migrations.sol");

module.exports = function(deployer) {
    deployer.deploy(Migrations);
};
