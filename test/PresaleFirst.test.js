import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const MintableToken = artifacts.require('MintableToken');
const PresaleFirst = artifacts.require('PresaleFirst');

contract('First Presale', function ([_, owner, buyer, fraud]) {
    const amount = 5;

    beforeEach(async () => {
        this.startTime = latestTime() + duration.years(1);
        this.endTime = this.startTime + duration.years(1);

        this.maxcap = web3.toWei('1500', 'ether');
        this.exceed = web3.toWei('300', 'ether');
        this.mininum = web3.toWei('0.5', 'ether');
        this.token = await MintableToken.new({ from: owner });
        this.rate = 115;

        this.presale = await PresaleFirst.new(
            // time
            this.startTime,
            this.endTime,
            // sale
            this.maxcap,
            this.exceed,
            this.token,
            this.rate,
            { from: owner }
        );

        await this.presale.addAddressToWhitelist(buyer);
    })

    it('cannot be sold before time limit', async () => {
        await this.presale.send(web3.toWei(amount, 'ether'), { from: buyer }).should.be.rejected;
    })

    it('cannot be sold just before time limit', async () => {
        await increaseTimeTo(this.startTime - duration.seconds(3));
        await this.presale.send(web3.toWei(amount, 'ether'), { from: buyer }).should.be.rejected;
    })

    it('cannot be sold to who are not in whitelist', async () => {
        await this.presale.send(web3.toWei(amount, 'ether'), { from: fraud }).should.be.rejected;
    })

    it('can be distribute Token just after time limit', async () => {
        await increaseTimeTo(this.startTime + duration.seconds(1));
        await this.presale.send(web3.toWei(amount, 'ether'), { from: buyer }).should.be.fulfilled;
        const balance = await this.token.balanceOf(buyer);
        balance.should.be.bignumber.equal(amount * this.rate);
    })

    it('can be distribute Token after time limit', async () => {
        await increaseTimeTo(this.startTime + duration.days(1));
        await this.presale.send(web3.toWei(amount, 'ether'), { from: buyer }).should.be.fulfilled;
        const balance = await this.token.balanceOf(buyer);
        balance.should.be.bignumber.equal(amount * this.rate);
    })

    it('cannot be distribute Token over exceed limit', async () => {
        //17,250,000
        await increaseTimeTo(this.startTime + duration.days(1));

    })
})
