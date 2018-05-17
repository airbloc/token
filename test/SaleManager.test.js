import ether from './helpers/ether'
import latestTime from './helpers/latestTime'
import { increaseTimeTo, duration } from './helpers/increaseTime'

const BigNumber = web3.BigNumber

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should()

const Whitelist = artifacts.require('Whitelist')
const MintableToken = artifacts.require('MintableToken')
const PresaleSecond = artifacts.require('PresaleSecond')
const SaleManager = artifacts.require('SaleManager')

// constructor(
//     address _sale
// )

contract('SaleManager', function (accounts) {
    const owner = accounts[1]
    const wallet = accounts[2]
    const test = accounts[3]
    const fraud = accounts[4]
    const buyers = accounts.slice(5, 11)

    let token
    let sale
    let manager

    const maxcap = 25
    const exceed = 15
    const minimum = 1
    const rate = 11500

    beforeEach(async () => {
        // Set presale second
        const whitelist = await Whitelist.new({ from: owner })
        await whitelist.addAddressesToWhitelist(
            buyers,
            { from: owner },
        ).should.be.fulfilled

        token = await MintableToken.new({ from: owner })
        sale = await PresaleSecond.new(
            ether(maxcap),
            ether(exceed),
            ether(minimum),
            rate,

            wallet,
            owner,

            whitelist.address,
            token.address,
            { from: owner },
        )

        await token.mint(
            sale.address,
            ether(maxcap) * rate,
            { from: owner }
        )
        // Set sale manager
        manager = await SaleManager.new(
            sale.address,
            { from: owner },
        )

        await sale.setDistributor(
            manager.address,
            { from: owner },
        ).should.be.fulfilled

        await sale.ignite({ from: owner })
        let cnt = 1
        for (let buyer of buyers)
            await sale.sendTransaction({ from: buyer, value: ether(cnt++) })
        await sale.extinguish({ from: owner })
    })

    it('release correctly', async () => {
        await manager.releaseMany(buyers, { from: owner })
        let cnt = 1
        for (let buyer of buyers) {
            const balance = await token.balanceOf(buyer)
            console.log(balance)
            balance.should.be.bignumber.equal(ether(cnt++) * rate)
        }
    })

    it('refund correctly', async () => {
        let beforeBalances = []
        let cnt

        cnt = 0
        for (let buyer of buyers) {
            const balance = await web3.eth.getBalance(buyer)
            beforeBalances[cnt++] = balance
        }

        cnt = 0
        await manager.refundMany(buyers, { from: owner })
        for (let buyer of buyers) {
            const after = await web3.eth.getBalance(buyer)
            const before = beforeBalances[cnt]
            const diff = after.minus(before)
            console.log(diff)
            diff.should.be.bignumber.equal(ether(++cnt))
        }
    })
})
