pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract ABL is StandardToken, Ownable {
    // Wallet
    address private dtb;    // distribution
    address private dev;    // developer

    // Token Distribution Rate
    uint256 public constant SUM = 100;   // totalSupply
    uint256 public constant DISTRIBUTION = 50; // distribution
    uint256 public constant DEVELOPERS = 50;   // developer

    // Token Information
    string public name = "Airbloc Token";
    string public symbol = "ABL";
    uint256 public decimals = 18;
    uint256 public totalSupply = SUM;

    function ABL(
        address _dtb,
        address _dev
        )
        public {
            require(_dtb != 0x0);
            require(_dev != 0x0);
            require(DISTRIBUTION + DEVELOPERS == SUM);

            dtb = _dtb;
            dev = _dev;

            balances[dtb] = DISTRIBUTION;
            emit Transfer(0x0, dtb, DISTRIBUTION);

            balances[dev] = DEVELOPERS;
            emit Transfer(0x0, dev, DEVELOPERS);
        }
}
