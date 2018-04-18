import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const MintableToken = artifacts.require('MintableToken');
const PresaleFirst = artifacts.require('PresaleFirst');

contract('First Presale', function ([_, owner, wallet, buyer, fraud]) {
    let token;
    let presale;

    const ethAmount = 5;
    const weiAmount = web3.toWei(ethAmount, 'ether');
    const startTime = latestTime() + duration.days(1);
    const endTime = startTime + duration.weeks(1);

    const maxEth = 1500;
    const exdEth = 300;
    const minEth = 0.5;

    const maxcap = web3.toWei(maxEth, 'ether');
    const exceed = web3.toWei(exdEth, 'ether');
    const mininum = web3.toWei(minEth, 'ether');

    const rate = 11500;

    beforeEach(async () => {
        token = await MintableToken.new({ from: owner });
        await token.mint(wallet, maxEth * rate * 100, { from: owner });

        presale = await PresaleFirst.new(
            // time
            startTime,
            endTime,
            // sale
            maxcap,
            exceed,
            mininum,

            wallet,
            token.address,
            rate / 100,
            { from: owner }
        );

        await presale.addAddressToWhitelist(buyer, { from: owner });
    })

    describe('accepting payments', () => {
        beforeEach(async () => {
            await increaseTimeTo(latestTime() + duration.days(2));
        })

        // it('should accept payments to whitelisted', async () => {
        //     await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.fulfilled;
        //     await presale.buyToken(fraud, { value: weiAmount, from: buyer }).should.be.fulfilled;
        // });

        it('should reject payments to not whitelisted', async () => {
            await presale.buyToken(fraud, { value: weiAmount, from: fraud }).should.be.rejected;
            await presale.buyToken(buyer, { value: weiAmount, from: fraud }).should.be.rejected;
        });

        it('should reject payments to addresses removed from whitelist', async () => {
            await presale.removeAddressFromWhitelist(buyer, { from: owner });
            await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
        });
    })

    describe('before time limit', () => {
        it('cannot be sold', async () => {
            await increaseTimeTo(latestTime() + startTime - duration.days(1));
            await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
        })

        it('cannot be sold (just before)', async () => {
            await increaseTimeTo(latestTime() + startTime - duration.seconds(3));
            await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
        })
    })

    // describe('after time limit', () => {
    //     it('can be distribute Token (just after)', async () => {
    //         await increaseTimeTo(latestTime() + startTime + duration.seconds(1));
    //         await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
    //         const balance = await token.balanceOf(buyer);
    //         balance.should.be.bignumber.equal(ethAmount * rate);
    //     })
    //
    //     it('can be distribute Token', async () => {
    //         await increaseTimeTo(latestTime() + startTime + duration.days(1));
    //         await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
    //         const balance = await token.balanceOf(buyer);
    //         balance.should.be.bignumber.equal(ethAmount * rate);
    //     })
    // })
    //
    // it('cannot be sold to who are not in whitelist', async () => {
    //     await presale.buyToken(buyer, { value: weiAmount, from: buyer }).should.be.rejected;
    // })
    //
    // it('cannot be distribute Token over exceed limit', async () => {
    //     //17,250,000
    //     await increaseTimeTo(latestTime() + startTime + duration.days(1));
    //
    // })
})
