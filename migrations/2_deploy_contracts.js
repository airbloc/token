const ETH = 1000000000000000000;

const ABL = artifacts.require('./ABL.sol');
const ABLG = artifacts.require('./ABLG.sol');
const ABLGExchanger = artifacts.require('./ABLGExchanger.sol');
const TokenTimelock = artifacts.require('./TokenTimelock.sol');
const PresaleFirst = artifacts.require('PresaleFirst');

const { increaseTimeTo, duration } = require('../test/helpers/increaseTime');

module.exports = async (deployer, network, accounts) => {
    const [_, owner, wallet, buyer, fraud] = accounts;

    let token;
    let presale;

    let startTime = Date.now() + duration.days(1);
    let endTime = startTime + duration.weeks(1);

    const maxEth = 1500 * ETH;
    const exdEth = 300 * ETH;
    const minEth = 0.5 * ETH;

    const rate = 11500;

    // deploy ABL token
    await deployer.deploy(ABL, owner, owner);
    await deployer.deploy(PresaleFirst, startTime, endTime, maxEth, exdEth, minEth, wallet, ABL.address, rate);
}
/*
uint256 _startTime,
uint256 _endTime,
uint256 _maxcap,
uint256 _exceed,
uint256 _minimum,
address _wallet,
address _token,
uint256 _rate

*/
