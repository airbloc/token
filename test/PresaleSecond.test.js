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
    const buyers = accounts.slice(4, 11)
    const test = accounts[10]
    const fraud = accounts[11]

    let token
    let sale

    const maxcap = 25
    const exceed = 15
    const minimum = 2
    const rate = 11500

    beforeEach(async () => {
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
            distributor,

            whitelist.address,
            token.address,
            { from: owner },
        )

        await token.mint(
            sale.address,
            ether(maxcap) * rate,
            { from: owner }
        )
    })

    describe('settings', () => {
        it('fraud cannot change whitelist address', async () => {
            const list = await Whitelist.new({ from: fraud })
            await sale.setWhitelist(list.address, { from: fraud }).should.be.rejected
        })

        it('fraud cannot change distributor', async () => {
            await sale.setDistributor(test, { from: fraud }).should.be.rejected
        })

        it('fraud cannot change wallet', async () => {
            await sale.setWallet(test, { from: fraud }).should.be.rejected
        })

        it('owner can change whitelist address', async () => {
            const before = await sale.List.call()
            const list = await Whitelist.new({ from: owner })
            await list.addAddressToWhitelist(fraud, { from: owner })
            await sale.setWhitelist(list.address, { from: owner })
            const after = await sale.List.call()
            console.log("B: ", before)
            console.log("A: ", after)
            after.should.not.be.equal(before)
            after.should.be.equal(list.address)
        })

        it('owner can change distributor', async () => {
            const before = await sale.distributor.call()
            await sale.setDistributor(test, { from: owner })
            const after = await sale.distributor.call()
            console.log("B: ", before)
            console.log("A: ", after)
            after.should.not.be.equal(before)
            after.should.be.equal(test)
        })

        it('owner can change wallet', async () => {
            const before = await sale.wallet.call()
            await sale.setWallet(test, { from: owner })
            const after = await sale.wallet.call()
            console.log("B: ", before)
            console.log("A: ", after)
            after.should.not.be.equal(before)
            after.should.be.equal(test)
        })
    })

    describe('control sale', () => {
        it('fraud cannot pause/resume sale', async () => {
            let paused

            await sale.pause({ from: fraud }).should.be.rejected
            paused = await sale.paused.call()
            paused.should.be.equal(false)

            await sale.resume({ from: fraud }).should.be.rejected
            paused = await sale.paused.call()
            paused.should.be.equal(false)
        })

        it('fraud cannot ignite/extinguish sale', async () => {
            let ignited

            await sale.ignite({ from: fraud }).should.be.rejected
            ignited = await sale.ignited.call()
            ignited.should.be.equal(false)

            await sale.extinguish({ from: fraud }).should.be.rejected
            ignited = await sale.ignited.call()
            ignited.should.be.equal(false)
        })

        it('owner can pause/resume sale', async () => {
            let paused;

            await sale.pause({ from: owner }).should.be.fulfilled
            paused = await sale.paused.call()
            paused.should.be.equal(true)

            await sale.resume({ from: owner }).should.be.fulfilled
            paused = await sale.paused.call()
            paused.should.be.equal(false)
        })

        it('owner can ignite/extinguish sale', async () => {
            let ignited;

            await sale.ignite({ from: owner}).should.be.fulfilled
            ignited = await sale.ignited.call()
            ignited.should.be.equal(true)

            await sale.extinguish({ from: owner }).should.be.fulfilled
            ignited = await sale.ignited.call()
            ignited.should.be.equal(false)
        })
    })

    describe('collect ether', () => {
        beforeEach(async () => {
            await sale.ignite({ from: owner })
        })

        it('non whitelisted buyer cannot buy token', async () => {
            await sale.sendTransaction({ from: fraud, value: ether(2000) }).should.be.rejected
        })

        it('buyer cannot buy under minimum', async () => {
            for (let buyer of buyers)
                await sale.sendTransaction({ from: buyer, value: ether(0.3) }).should.be.rejected
        })

        // maxcap = 25ETH
        it('buyer cannot buy over maxcap', async () => {
            for (let buyer of buyers)
                await sale.sendTransaction({ from: buyer, value: ether(3.5) }) //= weiRaised 24.5ETH

            const before = await web3.eth.getBalance(test)
            await sale.sendTransaction({ from: test, value: ether(2.5) }) //= 27ETH
            const after = await web3.eth.getBalance(test)
            console.log("B: ", before)
            console.log("A: ", after)
            before.minus(after).should.be.bignumber.above(ether(0.5)) //= refund 2ETH
        })

        // exceed = 15ETH
        it('buyer cannot buy over exceed', async () => {
            for (let buyer of buyers)
                await sale.sendTransaction({ from: buyer, value: ether(2) }) //= weiRaised 14ETH

            const before = await web3.eth.getBalance(test)
            await sale.sendTransaction({ from: test, value: ether(20) })
            const after = await web3.eth.getBalance(test)
            console.log("B: ", before)
            console.log("A: ", after)
            before.minus(after).should.be.bignumber.above(ether(11)) //= refund 9ETH
        })

        it('buyer cannot buy over both', async () => {
            for (let buyer of buyers)
                await sale.sendTransaction({ from: buyer, value: ether(3) }) //= weiRaised 21ETH

            const before = await web3.eth.getBalance(test)
            await sale.sendTransaction({ from: test, value: ether(20) })
            const after = await web3.eth.getBalance(test)
            console.log("B: ", before)
            console.log("A: ", after)
            before.minus(after).should.be.bignumber.above(ether(4)) //= refund 16ETH
        })
    })

    describe('distribution', () => {
        beforeEach(async () => {
            await sale.ignite({ from: owner })

            for (let buyer of buyers)
                await sale.sendTransaction({ from: buyer, value: ether(3) })
        })

        it('fraud cannot release token', async () => {
            await sale.release(test, { from: fraud }).should.be.rejected
        })

        it('fraud cannot refund token', async () => {
            await sale.refund(test, { from: fraud }).should.be.rejected
        })

        it('fraud cannot withdraw token', async () => {
            await sale.withdrawToken({ from: fraud }).should.be.rejected
        })

        it('fraud cannot withdraw ether', async () => {
            await sale.withdrawEther({ from: fraud }).should.be.rejected
        })

        describe('when not on sale', () => {
            beforeEach(async () => {
                await sale.extinguish({ from: owner })
            })

            it('distributor can release token', async () => {
                for (let buyer of buyers){
                    const before = await token.balanceOf(buyer)
                    await sale.release(buyer, { from: distributor }).should.be.fulfilled
                    const after = await token.balanceOf(buyer)
                    console.log("B: ", before)
                    console.log("A: ", after)
                    after.minus(before).should.be.bignumber.equal(ether(3) * rate)
                }
            })

            it('distributor can refund ether', async () => {
                for (let buyer of buyers){
                    const before = await web3.eth.getBalance(buyer)
                    await sale.refund(buyer, { from: distributor }).should.be.fulfilled
                    const after = await web3.eth.getBalance(buyer)
                    console.log("B: ", before)
                    console.log("A: ", after)
                    after.minus(before).should.be.bignumber.equal(ether(3))
                }
            })

            it('owner can withdraw token', async () => {
                const before = await token.balanceOf(wallet)
                await sale.withdrawToken({ from: owner }).should.be.fulfilled
                const after = await token.balanceOf(wallet)
                console.log("B: ", before)
                console.log("A: ", after)
                after.minus(before).should.be.bignumber.equal(ether(maxcap) * rate)
            })

            it('owner can withdraw ether', async () => {
                const before = await web3.eth.getBalance(wallet)
                await sale.withdrawEther({ from: owner }).should.be.fulfilled
                const after = await web3.eth.getBalance(wallet)
                console.log("B: ", before)
                console.log("A: ", after)
                after.minus(before).should.be.bignumber.equal(ether(21))
            })
        })

        describe('when on sale', () => {
            it('distributor cannot release token', async () => {
                for (let buyer of buyers)
                    await sale.release(buyer, { from: distributor }).should.be.rejected
            })

            it('distributor cannot refund ether', async () => {
                for (let buyer of buyers)
                    await sale.refund(buyer, { from: distributor }).should.be.rejected
            })

            it('owner cannot withdraw token', async () => {
                await sale.withdrawToken({ from: owner }).should.be.rejected
            })

            it('owner cannot withdraw ether', async () => {
                await sale.withdrawEther({ from: owner }).should.be.rejected
            })
        })
    })
})
