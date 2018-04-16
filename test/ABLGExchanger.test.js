const ABL = artifacts.require('./ABL.sol');
const ABLG = artifacts.require('./ABLG.sol');
const ABLGE = artifacts.require('./ABLGExchanger.sol');


contract('Airbloc Genesis Token Exchanger', async (accounts) => {
    let abl;
    let ablg;
    let exchanger;

    const dtb = accounts[0];
    const dev = accounts[1];
    const test = accounts[2];
    const amount = 10;

    beforeEach(async () => {
        abl = await ABL.new(dtb, dev);
        ablg = await ABLG.new();
        exchanger = await ABLGE.new(abl.address, ablg.address, dtb);
    })

    it('', async () => {

    })

    it('after', async () => {

    })
})
