import ether from './helpers/ether';

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const ABL = artifacts.require('ABL');
const ABLG = artifacts.require('ABLG');
const ABLGE = artifacts.require('ABLGExchanger');


contract('Airbloc Genesis Token Exchanger', function ([_, owner, buyer, buyer1, buyer2, buyer3, buyer4, buyer5, fraud]) {
    let abl;
    let ablg;
    let exchanger;

    const buyers = [
        buyer1,
        buyer2,
        buyer3,
        buyer4,
        buyer5
    ];

    // big fucking amount
    const bfAmount = 100000000;
    // normal amount
    const nmAmount = 145;

    beforeEach(async () => {
        abl = await ABL.new(owner, owner, { from: owner });
        ablg = await ABLG.new({ from: owner });
        exchanger = await ABLGE.new(abl.address, ablg.address, { from: owner });

        await abl.unlock({ from: owner });
        await abl.mint(exchanger.address, bfAmount, { from: owner });
        for (let b of buyers) {
            await ablg.mint(b, nmAmount, { from: owner });
        }
        await exchanger.addHolders(buyers, { from: owner });
    })

    describe('restriction', () => {
        it('cannot call onlyOwner functions', async () => {
            await exchanger.distribute({ from: fraud }).should.be.rejected;
            await exchanger.addHolder(buyer, { from: fraud }).should.be.rejected;
            await exchanger.addHolders(buyers, { from: fraud }).should.be.rejected;
            await exchanger.removeHolder(buyer, { from: fraud }).should.be.rejected;
            await exchanger.removeHolders(buyer, { from: fraud }).should.be.rejected;
        })
    });

    describe('distribution', () => {
        it('should distribute correctly', async () => {
            await exchanger.distribute({ from: owner }).should.be.fulfilled;
            for (let b of buyers) {
                const balance = await abl.balanceOf(b);
                balance.should.be.bignumber.equal(ether(nmAmount));
            }
        });

        it('should remain genesis token', async () => {
            await exchanger.distribute({ from: owner }).should.be.fulfilled;
            for (let b of buyers) {
                const balance = await ablg.balanceOf(b);
                balance.should.be.bignumber.equal(ether(nmAmount));
            }
        });

        it('cannot distribute twice', async() => {
            await exchanger.distribute({ from: owner }).should.be.fulfilled;
            await exchanger.distribute({ from: owner }).should.be.rejected;
        });
    });
})
