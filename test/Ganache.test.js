contract('Ganache-cli', async (accounts) => {
  const test = accounts[0];

  it('should creates correctly number of accounts', async () => {
    assert.equal(accounts.length, 50);
  });

  it('should give correctly amount of eth', async () => {
    assert.equal(web3.eth.getBalance(accounts[1]).c, 5000000);
  });
})
