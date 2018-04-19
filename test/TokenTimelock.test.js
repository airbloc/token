import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const MintableToken = artifacts.require('MintableToken');
const OwnedTokenTimelock = artifacts.require('OwnedTokenTimelock');

contract('OwnedTokenTimelock', function ([_, owner, beneficiary]) {
    const amount = new BigNumber(100);

    beforeEach(async function () {
        this.token = await MintableToken.new({ from: owner });
        this.releaseTime = duration.years(1);
        this.timelock = await OwnedTokenTimelock.new(this.token.address, owner, beneficiary, this.releaseTime);
        await this.token.mint(this.timelock.address, amount, { from: owner });
    });

    it('can be change release time by owner', async function() {
        this.releaseTime = duration.weeks(1);
        await this.timelock.changeReleaseTime(this.releaseTime, { from: owner });
        const time = await this.timelock.releaseTime();
        time.should.be.bignumber.equal(this.releaseTime);
    })

    it('can be withdraw before time limit by owner', async function() {
        await this.timelock.withdraw({ from: owner })
        const balance = await this.token.balanceOf(owner);
        balance.should.be.bignumber.equal(amount);
    })

    it('cannot be released before time limit', async function () {
        await this.timelock.release().should.be.rejected;
    });

    it('cannot be released just before time limit', async function () {
        await increaseTimeTo(latestTime() + this.releaseTime - duration.seconds(3));
        await this.timelock.release().should.be.rejected;
    });

    it('can be released just after limit', async function () {
        await increaseTimeTo(latestTime() + this.releaseTime + duration.seconds(1));
        await this.timelock.release().should.be.fulfilled;
        const balance = await this.token.balanceOf(beneficiary);
        balance.should.be.bignumber.equal(amount);
    });

    it('can be released after time limit', async function () {
        await increaseTimeTo(latestTime() + this.releaseTime + duration.years(1));
        await this.timelock.release().should.be.fulfilled;
        const balance = await this.token.balanceOf(beneficiary);
        balance.should.be.bignumber.equal(amount);
    });

    it('cannot be released twice', async function () {
        await increaseTimeTo(latestTime() + this.releaseTime + duration.years(1));
        await this.timelock.release().should.be.fulfilled;
        await this.timelock.release().should.be.rejected;
        const balance = await this.token.balanceOf(beneficiary);
        balance.should.be.bignumber.equal(amount);
    });
});
