const Whitelist = artifacts.require('Whitelist');


contract('Whitelist', async (accounts) => {
    let wi;
    const fraud = accounts[1];
    const test = accounts[2];

    beforeEach(async() => {
        wi = await Whitelist.new();
    })

    it('must for only owner', async () => {
        await wi.register(test, {from: fraud})
            .catch((error) => {
                assert.equal(error.message, 'VM Exception while processing transaction: revert');
            })
    })

    it('should be able to register account', async () => {
        await wi.unregister(test);
        await wi.register(test);
        assert(await wi.whitelist.call(test));
    });

    it('should be able to unregister account', async () => {
        await wi.register(test);
        await wi.unregister(test);
        assert(!(await wi.whitelist.call(test)));
    });
})
