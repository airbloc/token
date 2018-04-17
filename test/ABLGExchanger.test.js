const ABL = artifacts.require('ABL');
const ABLG = artifacts.require('ABLG');
const ABLGE = artifacts.require('ABLGExchanger');


contract('Airbloc Genesis Token Exchanger', function ([_, dtb, dev, test]) {
    const amount = 10;

    beforeEach(async () => {
        this.abl = await ABL.new(dtb, dev);
        this.ablg = await ABLG.new();
        this.exchanger = await ABLGE.new(this.abl.address, this.ablg.address, dtb);
    })

    
})
