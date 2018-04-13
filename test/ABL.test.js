const ABL = artifacts.require('ABL');


contract('Airbloc Token', async (accounts) => {
    let abli;
    const dtb = accounts[0];
    const dev = accounts[1];

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
})
