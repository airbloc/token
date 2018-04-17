const ABL = artifacts.require('ABL');
const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('Airbloc Token', function ([_, dtb, dev, test]) {
    let abli;
    const amount = 1;

    const _name = 'Airbloc Token';
    const _symbol = 'ABL';
    const _decimals = 18;

    before(async () => {
        abli = await ABL.new(dtb, dev);
    })

    // Token Options
    it('has a name', async () => {
        const name = await abli.name()
        name.should.be.equal(_name);
    });

    it('has a symbol', async () => {
        const symbol = await abli.symbol()
        symbol.should.be.equal(_symbol);
    });

    it('has 18 decimals', async () => {
        const decimals = await abli.decimals()
        decimals.should.be.bignumber.equal(_decimals);
    });

    // Mint
    it("should mint correctly", async () => {
        const beforeBalance = await abli.balanceOf(dtb);
        const beforeTotalSupply = await abli.totalSupply();

        await abli.mint(dtb, amount);

        const afterBalance = await abli.balanceOf(dtb);
        const afterTotalSupply = await abli.totalSupply();

        const balanceGap = afterBalance - beforeBalance;
        balanceGap.should.be.equal(amount, 'there are some problems in minting process');
        const supplyGap = afterTotalSupply - beforeTotalSupply;
        supplyGap.should.be.equal(amount, 'there are some problems in minting process');
    });

    // Burn
    it("should burn correctly", async () => {
        const beforeBalance = await abli.balanceOf(dtb);
        const beforeTotalSupply = await abli.totalSupply();

        await abli.burn(amount, {from: dtb});

        const afterBalance = await abli.balanceOf(dtb);
        const afterTotalSupply = await abli.totalSupply();

        const balanceGap = beforeBalance - afterBalance;
        balanceGap.should.be.equal(amount, 'there are some problems in burning process');
        const supplyGap = beforeTotalSupply - afterTotalSupply;
        supplyGap.should.be.equal(amount, 'there are some problems in burning process');
    });
})
