pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract AirblocToken is MintableToken {
    // Wallet
    address pvt;
    address pre;
    address pub;
    address dev;

    // Token Distribution Rate
    uint256 constant SUM = 300000000;
    uint256 constant PVT = 43500000;
    uint256 constant PRE = 44750000;
    uint256 constant PUB = 80000000;
    uint256 constant DEV = 131750000;

    // Token Information
    string public name = "Airbloc Token";
    string public symbol = "ABL";
    uint256 public decimals = 18;

    function AirblocToken(
        address _pvt,
        address _pre,
        address _pub,
        address _dev
        )
        public {
            require(_pvt != 0x0);
            require(_pre != 0x0);
            require(_pub != 0x0);
            require(_dev != 0x0);
            require(PVT + PRE + PUB + DEV == SUM);

            pvt = _pvt;
            pre = _pre;
            pub = _pub;
            dev = _dev;

            balances[pvt] = PVT;
            balances[pre] = PRE;
            balances[pub] = PUB;
            balances[dev] = DEV;
        }
}
