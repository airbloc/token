const ABLG = artifacts.require("ABLG");
const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract("Airbloc Genesis Token", function ([_, test]) {
    let ablgi;
    const amount = 10;

    const _name = 'Airbloc Genesis Token';
    const _symbol = 'ABLG';
    const _decimals = 18;

    before(async() => {
        ablgi = await ABLG.new();
    })

    it('has a name', async () => {
        const name = await ablgi.name();
        name.should.be.equal(_name);
    });

    it('has a symbol', async () => {
        const symbol = await ablgi.symbol();
        symbol.should.be.equal(_symbol);
    });

    it('has 18 decimals', async () => {
        const decimals = await ablgi.decimals();
        decimals.should.be.bignumber.equal(_decimals);
    });

    // Mint
    it("should mint correctly", async() => {
        const beforeBalance = await ablgi.balanceOf(test);
        const beforeTotalSupply = await ablgi.totalSupply();

        await ablgi.mint(test, amount);

        const afterBalance = await ablgi.balanceOf(test);
        const afterTotalSupply = await ablgi.totalSupply();

        const balanceGap = afterBalance - beforeBalance;
        balanceGap.should.be.equal(amount, 'there are some problems in minting process');
        const supplyGap = afterTotalSupply - beforeTotalSupply;
        supplyGap.should.be.equal(amount, 'there are some problems in minting process');
    });

    // Burn
    it("should burn correctly", async() => {
        const beforeBalance = await ablgi.balanceOf(test);
        const beforeTotalSupply = await ablgi.totalSupply();

        await ablgi.burn(amount, {from: test});

        const afterBalance = await ablgi.balanceOf(test);
        const afterTotalSupply = await ablgi.totalSupply();

        const balanceGap = beforeBalance - afterBalance;
        balanceGap.should.be.equal(amount, 'there are some problems in burning process');
        const supplyGap = beforeTotalSupply - afterTotalSupply;
        supplyGap.should.be.equal(amount, 'there are some problems in burning process');
    });
})
