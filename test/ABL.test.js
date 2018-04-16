const ABL = artifacts.require('./ABL.sol');


contract('Airbloc Token', async (accounts) => {
    let abli;
    const dtb = accounts[0];
    const dev = accounts[1];
    const amount = 1;

    beforeEach(async () => {
        abli = await ABL.new(dtb, dev);
    })

    it('has a name', async () => {
        const name = await abli.name();
        assert.equal(name, 'Airbloc Token');
    });

    it('has a symbol', async () => {
        const symbol = await abli.symbol();
        assert.equal(symbol, 'ABL');
    });

    it('has 18 decimals', async () => {
        const decimals = await abli.decimals();
        assert(decimals.eq(18));
    });

    it('assigns the initial total supply to the creator', async function () {
        const totalSupply = await abli.totalSupply();
        const dtbBalance = await abli.balanceOf(dtb);
        const devBalance = await abli.balanceOf(dev);

        assert.equal(dtbBalance.toNumber() + devBalance.toNumber(), totalSupply);
        assert(dtbBalance.eq(50));
        assert(devBalance.eq(50));
    });

    // Mint
    it("should mint correctly", async() => {
        const beforeBalance = await abli.balanceOf(dtb);
        const beforeTotalSupply = await abli.totalSupply();

        await abli.mint(dtb, amount);

        const afterBalance = await abli.balanceOf(dtb);
        const afterTotalSupply = await abli.totalSupply();

        assert.equal(afterBalance - beforeBalance, amount, 'there are some problems in minting process');
        assert.equal(afterTotalSupply - beforeTotalSupply, amount, 'there are some problems in minting process')
    });

    // Burn
    it("should burn correctly", async() => {
        await abli.mint(dtb, amount);

        const beforeBalance = await abli.balanceOf(dtb);
        const beforeTotalSupply = await abli.totalSupply();

        await abli.burn(amount, {from: dtb});

        const afterBalance = await abli.balanceOf(dtb);
        const afterTotalSupply = await abli.totalSupply();

        assert.equal(beforeBalance - afterBalance, amount, 'there are some problems in burning process');
        assert.equal(beforeTotalSupply - afterTotalSupply, amount, 'there are some problems in burning process')
    });
})
