const Whitelist = artifacts.require('Whitelist');

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('Whitelist', async (accounts) => {
    let wi;
    const fraud = accounts[1];
    const test = accounts[2];

    beforeEach(async() => {
        wi = await Whitelist.new();
    })

    it('must for only owner', async () => {
        await wi.register(test, {from: fraud}).should.be.rejected;
    })

    it('should be able to register account', async () => {
        await wi.register(test);
        await wi.whitelist.call(test).should.be.true;
    });

    it('should be able to unregister account', async () => {
        await wi.register(test);
        await wi.unregister(test);
        await wi.whitelist.call(test).should.be.false;
    });
})
