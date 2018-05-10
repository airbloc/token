import ether from './helpers/ether'
import latestTime from './helpers/latestTime'
import { increaseTimeTo, duration } from './helpers/increaseTime'

const BigNumber = web3.BigNumber

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should()

const MintableToken = artifacts.require('MintableToken')
const Whitelist = artifacts.require('Whitelist')
const PresaleSecond = artifacts.require('PresaleSecond')

// constructor (
//     uint256 _maxcap,
//     uint256 _exceed,
//     uint256 _minimum,
//     uint256 _rate,
//     uint256 _startTime,
//     uint256 _endTime,
//     address _wallet,
//     address _distributor,
//     address _whitelist,
//     address _token
// )

contract('PresaleSecond', function (accounts) {
    const owner = accounts[1]
    const wallet = accounts[2]
    const distributor = accounts[3]
    const fraud = accounts[4]
    const buyers = accounts.slice(5, 10)

    const maxcap = 20
    const exceed = 10
    const minimum = 2
    const rate = 11500

    beforeEach(async () => {
        this.startTime = latestTime()
        this.endTime = this.startTime + duration.days(3)

        this.whitelist = await Whitelist.new({ from: owner })
        await this.whitelist.addAddressesToWhitelist(
            buyers,
            { from: owner },
        ).should.be.fulfilled

        this.token = await MintableToken.new({ from: owner })
        this.sale = await PresaleSecond.new(
            ether(maxcap),
            ether(exceed),
            ether(minimum),
            rate,

            this.startTime,
            this.endTime,

            wallet,
            distributor,

            whitelist,
            this.token.address,
            { from: owner },
        )
        await this.token.mint(this.sale.address, maxcap * rate, { from: owner })
    })

    // before ignite
    describe('before sale', () => {
        describe('owner', () => {
            describe('startTime', () => {
                it('can set startTime', async () => {
                    const before = this.sale.startTime
                    await this.sale.setStartTime(
                        this.startTime +
                        duration.days(1)
                    ).should.be.fulfilled
                    const after = this.sale.startTime
                })

                it('cannot set startTime to past', async () => {
                    await this.sale.setStartTime(
                        latestTime() -
                        duration.days(1)
                    ).should.be.rejected
                })

                it('cannot set startTime after endTime', async () => {
                    await this.sale.setStartTime(
                        this.endTime +
                        duration.days(1)
                    ).should.be.rejected
                })
            }

            describe('endTime', () => {
                it('can set endTime', async () => {
                    const before = this.sale.endTime
                    await this.sale.setEndTime(
                        this.startTime +
                        duration.days(1)
                    ).should.be.fulfilled
                    const after = this.sale.endTime
                })

                it('cannot set endTime to past', async () => {
                    await this.sale.setEndTime(
                        latestTime() -
                        duration.days(1)
                    ).should.be.rejected
                })

                it('cannot set endTime before startTime', async () => {
                    await this.sale.setEndTime(
                        this.startTime -
                        duration.days(1)
                    ).should.be.rejected
                })
            })

            it('can change whitelist contract', async () => {
                const list = await Whitelist.new({ from: owner })
                await list.addAddressToWhitelist(fraud, { from: owner })
                const isWhitelisted = await this.sale.List.whitelist(fraud)
                isWhitelisted.should.be.equal(true)
            })
        })
    })
})
