import ether from './helpers/ether';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const MintableToken = artifacts.require('MintableToken');
const PresaleFirst = artifacts.require('PresaleFirst');

contract('First Presale', function ([_, owner, wallet, buyer, buyer1, buyer2, buyer3, buyer4, buyer5, fraud]) {
    let token;
    let presale;
    let startTime;
    let endTime;
    const buyers = [
        buyer1,
        buyer2,
        buyer3,
        buyer4,
        buyer5
    ];

    const maxEth = 1500;
    const exdEth = 300;
    const minEth = 0.5;
    const rate = 11500;

    beforeEach(async () => {
        token = await MintableToken.new({ from: owner });

        startTime = latestTime() + duration.days(1);
        endTime = startTime + duration.weeks(1);

        presale = await PresaleFirst.new(
            // time
            startTime,
            endTime,
            // sale
            ether(maxEth),
            ether(exdEth),
            ether(minEth),

            wallet,
            token.address,
            rate / 100,
            { from: owner }
        );
        await token.mint(presale.address, maxEth * rate, { from: owner });

        await presale.addAddressToWhitelist(buyer, { from: owner }).should.be.fulfilled;
        const isPaused = await presale.paused();
        isPaused.should.be.equal(false);
        const isWhitelisted = await presale.whitelist(buyer);
        isWhitelisted.should.be.equal(true);
    });

    describe('before time limit', () => {
        it('cannot be sold', async () => {
            await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.rejected;
        });

        it('cannot be sold (just before)', async () => {
            await increaseTimeTo(startTime - duration.seconds(3));
            await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.rejected;
        });
    });

    describe('after time limit', () => {
        beforeEach(async () => {
            await increaseTimeTo(startTime + duration.days(3));
        });

        describe('accept payments', () => {
            it('should accept payments to whitelisted', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.fulfilled;
                await presale.collect(buyer, { from: buyer, value: ether(10) }).should.be.fulfilled;
                await presale.collect(fraud, { from: buyer, value: ether(10) }).should.be.fulfilled;
            });

            it('should reject payments to not whitelisted', async () => {
                await presale.sendTransaction({ from: fraud, value: ether(10) }).should.be.rejected;
                await presale.collect(fraud, { from: fraud, value: ether(10) }).should.be.rejected;
                await presale.collect(buyer, { from: fraud, value: ether(10) }).should.be.rejected;
            });

            it('should accept payments to who already paid', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.fulfilled;
                await presale.collect(buyer, { from: buyer, value: ether(10) }).should.be.fulfilled;
            });

            it('should reject payments to who already paid over exceed', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(350) }).should.be.fulfilled;
                await presale.sendTransaction({ from: buyer, value: ether(350) }).should.be.rejected;
            });

            it('should reject payments to who paid under minimum', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(0.3) }).should.be.rejected;
            });
        });

        describe('processing payments', () => {
            it('should get refund when paid over exceed', async () => {
                const beforeBalance = await web3.eth.getBalance(buyer);

                await presale.sendTransaction({ from: buyer, value: ether(350) }).should.be.fulfilled;

                const afterBalance = await web3.eth.getBalance(buyer);

                const diff = beforeBalance.toNumber() - afterBalance.toNumber();
                diff.should.be.above(ether(300).toNumber());
            });

            it('should get refund when paid over exceed', async () => {
                const beforeBalance = await web3.eth.getBalance(buyer);

                await presale.sendTransaction({ from: buyer, value: ether(200) }).should.be.fulfilled;
                await presale.sendTransaction({ from: buyer, value: ether(200) }).should.be.fulfilled;

                const afterBalance = await web3.eth.getBalance(buyer);

                const diff = beforeBalance.toNumber() - afterBalance.toNumber();
                diff.should.be.above(ether(300).toNumber());
            });
        });

        describe('distribution', () => {
            it('should distribute correct amount of token to one', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.fulfilled;

                await increaseTimeTo(endTime + duration.days(3));
                await presale.release({ from: owner }).should.be.fulfilled;

                const balance = await token.balanceOf(buyer);
                balance.should.be.bignumber.equal(10 * rate);
            });

            it('should distribute correct amount of token to many', async () => {
                await presale.addAddressesToWhitelist(buyers, { from: owner }).should.be.fulfilled;

                for (let b of buyers) {
                    await presale.sendTransaction({ from: b, value: ether(10) }).should.be.fulfilled;
                }

                await increaseTimeTo(endTime + duration.days(3));
                await presale.release({ from: owner }).should.be.fulfilled;

                for (let b of buyers) {
                    const balance = await token.balanceOf(b);
                    balance.should.be.bignumber.equal(10 * rate);
                }
            });

            it('cannot release twice', async () => {
                await presale.sendTransaction({ from: buyer, value: ether(10) }).should.be.fulfilled;

                await increaseTimeTo(endTime + duration.days(3));
                await presale.release({ from: owner }).should.be.fulfilled;
                await presale.release({ from: owner }).should.be.rejected;
            });
        });
    });
});
