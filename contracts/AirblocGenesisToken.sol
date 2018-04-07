pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract AirblocGenesisToken is MintableToken {

    mapping (address => uint256) holders;

    // Token Information
    string public name = "Airbloc Genesis Token";
    string public symbol = "ABLG";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

    function addHodler(
        address _holder,
        uint256 _amount
        )
        public {
            require(mint(_holder, _amount));
        }
}
