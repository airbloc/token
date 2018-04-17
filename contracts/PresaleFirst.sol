pragma solidity ^0.4.19;

import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/ownership/Whitelist.sol";
import "./zeppelin-solidity/contracts/lifecycle/Pausable.sol";


contract PresaleFirst {


    /* this.startTime,
    this.endTime,
    // sale
    this.maxcap,
    this.exceed,
    this.token,
    this.rate, */

    function PresaleFirst(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxcap,
        uint256 _exceed,
        ERC20 _token,
        uint256 _rate
        ) public {


    }

    function () public payable {
        buyToken(msg.sender);
    }

    function buyToken(address buyer) public whenNotPaused {
        require(buyer != address(0));
        require(msg.value > 0);

        

    }
}
