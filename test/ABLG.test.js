const ABLG = artifacts.require("./ABLG.sol");


contract("Airbloc Genesis Token", async (accounts) => {
    let ablgi;
    const test = accounts[0];
    const amount = 10;

    beforeEach(async() => {
        ablgi = await ABLG.new();
    })

    it('has a name', async () => {
        const name = await ablgi.name();
        assert.equal(name, 'Airbloc Genesis Token');
    });

    it('has a symbol', async () => {
        const symbol = await ablgi.symbol();
        assert.equal(symbol, 'ABLG');
    });

    it('has 18 decimals', async () => {
        const decimals = await ablgi.decimals();
        assert(decimals.eq(18));
    });

    // Mint
    it("should mint correctly", async() => {
        const beforeBalance = await ablgi.balanceOf(test);
        const beforeTotalSupply = await ablgi.totalSupply();

        await ablgi.mint(test, amount);

        const afterBalance = await ablgi.balanceOf(test);
        const afterTotalSupply = await ablgi.totalSupply();

        assert.equal(afterBalance - beforeBalance, amount, 'there are some problems in minting process');
        assert.equal(afterTotalSupply - beforeTotalSupply, amount, 'there are some problems in minting process')
    });

    // Burn
    it("should burn correctly", async() => {
        await ablgi.mint(test, amount);

        const beforeBalance = await ablgi.balanceOf(test);
        const beforeTotalSupply = await ablgi.totalSupply();

        await ablgi.burn(amount, {from: test});

        const afterBalance = await ablgi.balanceOf(test);
        const afterTotalSupply = await ablgi.totalSupply();

        assert.equal(beforeBalance - afterBalance, amount, 'there are some problems in burning process');
        assert.equal(beforeTotalSupply - afterTotalSupply, amount, 'there are some problems in burning process')
    });
})
